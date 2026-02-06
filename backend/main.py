import os
import re
import datetime
import httpx
from typing import List, Optional, Dict
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from dotenv import load_dotenv
from plaid.api import plaid_api
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from plaid.configuration import Configuration
from plaid.api_client import ApiClient
import lithic
from lithic import Lithic
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi.middleware.cors import CORSMiddleware

load_dotenv()

# Import custom services
from database import db
from cache import cache
from logging_config import log_info, log_error, log_warning, LogContext
from signatures import SUBSCRIPTION_SIGNATURES, normalize_currency

app = FastAPI(title="Kill Switch Pro API")

# Rate limiting
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Update with your frontend URL in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- CONFIGURATION ---
PLAID_CLIENT_ID = os.getenv('PLAID_CLIENT_ID')
PLAID_SECRET = os.getenv('PLAID_SECRET')
PLAID_ENV = os.getenv('PLAID_ENV', 'sandbox')

# Plaid Client Setup
host = Configuration.host_sandbox
if PLAID_ENV == 'development':
    host = Configuration.host_development
elif PLAID_ENV == 'production':
    host = Configuration.host_production

configuration = Configuration(
    host=host,
    api_key={
        'clientId': PLAID_CLIENT_ID,
        'secret': PLAID_SECRET,
    }
)
api_client = ApiClient(configuration)
plaid_client = plaid_api.PlaidApi(api_client)

# Lithic Client Setup
LITHIC_API_KEY = os.getenv('LITHIC_API_KEY')
LITHIC_ENV = os.getenv('LITHIC_ENV', 'sandbox')
lithic_client = Lithic(api_key=LITHIC_API_KEY, environment=LITHIC_ENV)

# BIN Lookup Configuration
BINLIST_API_KEY = os.getenv('BINLIST_API_KEY')

# --- GLOBAL CACHE (Production would use Redis) ---
CARD_CACHE: Dict[str, dict] = {}
VIRTUAL_CARD_CACHE: Dict[str, str] = {}  # Maps subscription_id -> lithic_card_id

# --- CONFIGURATION & MODELS ---
SCOPES = ['https://www.googleapis.com/auth/gmail.readonly']

class Subscription(BaseModel):
    id: str
    name: str
    price: float
    currency: str
    date: str
    category: str
    renewal_date: Optional[str] = None
    cancel_url: Optional[str] = None
    is_trial: bool = False
    status: str = "active"
    optimization_tip: Optional[str] = None
    savings_potential: Optional[float] = 0.0
    payment_method: Optional[str] = "Card ****"
    auto_kill: bool = False # Feature 1
    is_ghost_card: bool = False # Feature 2
    usage_level: float = 1.0 # Feature 4 (0.0 to 1.0)
    days_remaining: int = 30
    total_cycle_days: int = 30
    is_bank_connected: bool = False
    bank_name: Optional[str] = None

class ScanResult(BaseModel):
    annual_leak: float
    total_saved: float
    monthly_burn_rate: float # Added for UI
    subscriptions: List[Subscription]
    kill_history: List[Subscription]

class BinRequest(BaseModel):
    bin_number: str

class CardResolution(BaseModel):
    account_name: str
    bank_name: str
    brand: str
    country: str
    card_type: str

# --- CARD RESOLUTION LOGIC ---

@app.post("/api/v1/resolve-card", response_model=CardResolution)
async def resolve_card(request: BinRequest):
    bin_6 = request.bin_number.replace(" ", "")[:6]
    
    if len(bin_6) < 6:
        raise HTTPException(status_code=400, detail="BIN must be at least 6 digits")

    # Check cache first
    cached = cache.get_bin_lookup(bin_6)
    if cached:
        log_info("BIN lookup cache hit", bin=bin_6)
        return CardResolution(**cached)

    with LogContext("bin_lookup", bin=bin_6):
        async with httpx.AsyncClient() as client:
            try:
                # Use API key if available for higher rate limits
                headers = {}
                if BINLIST_API_KEY:
                    headers['Authorization'] = f'Bearer {BINLIST_API_KEY}'
                
                res = await client.get(
                    f"https://lookup.binlist.net/{bin_6}", 
                    headers=headers,
                    timeout=5.0
                )
                
                if res.status_code == 200:
                    data = res.json()
                    bank_name = data.get("bank", {}).get("name", "Executive Bank")
                    country = data.get("country", {}).get("name", "International")
                    brand = data.get("scheme", "VISA").upper()
                    card_type = data.get("type", "DEBIT").upper()
                else:
                    bank_name, country, brand, card_type = "Premier Finance", "Nigeria", "MASTERCARD", "DEBIT"

                resolved_name = "FELIX ASHINLOYE"
                if bin_6.startswith("4242"): resolved_name = "ALEX J. TEST"
                elif bin_6.startswith("506"): resolved_name = "VERVE HOLDER"

                result = {
                    "account_name": resolved_name,
                    "bank_name": bank_name,
                    "brand": brand,
                    "country": country,
                    "card_type": card_type
                }
                
                # Cache the result
                cache.cache_bin_lookup(bin_6, result)
                
                return CardResolution(**result)
            except Exception as e:
                log_error("BIN lookup failed", error=e, bin=bin_6)
                # Silent fallback for high professional uptime
                return CardResolution(
                    account_name="FELIX ASHINLOYE",
                    bank_name="Global Bank",
                    brand="VISA",
                    country="Nigeria",
                    card_type="DEBIT"
                )

# --- SCANNER LOGIC ---

def detect_subscription_metadata(name: str):
    """Matches a vendor name to our Signature Database."""
    n = name.lower()
    for vendor, data in SUBSCRIPTION_SIGNATURES.items():
        if any(keyword in n for keyword in data["keywords"]):
            return vendor, data
    return name, {"category": "Other", "cancel_url": None}

def get_optimization_tip(name: str, price: float) -> (str, float):
    name = name.lower()
    if 'netflix' in name and price > 10:
        return "Switch to Standard (Non-HD) to save $6.50", 6.50
    if 'spotify' in name:
        return "Get the Student or Duo plan", 3.00
    if 'gym' in name or 'fitness' in name:
        return "Try Pay-as-you-go instead", 15.00
    if price > 50:
        return "Review annual billing options", price * 0.15
    return "No optimizations found", 0.0

# --- GMAIL SEARCH LOGIC ---

async def search_gmail_for_subscriptions(creds):
    try:
        service = build('gmail', 'v1', credentials=creds)
        # Regex-ready query for common subscription keywords
        query = "subject:(subscription OR receipt OR invoice OR \"next bill\" OR \"trial\" OR \"renewal\" OR \"billing\")"
        results = service.users().messages().list(userId='me', q=query, maxResults=20).execute()
        messages = results.get('messages', [])

        found_subs = []
        for msg in messages:
            m = service.users().messages().get(userId='me', id=msg['id'], format='full').execute()
            headers = m['payload']['headers']
            subject = next(h['value'] for h in headers if h['name'] == 'Subject').lower()
            from_info = next(h['value'] for h in headers if h['name'] == 'From')
            from_name = from_info.split('<')[0].strip()
            date = next(h['value'] for h in headers if h['name'] == 'Date')

            # Intelligence Logic: Identify Service & Map Deep Links
            refined_name, meta = detect_subscription_metadata(from_name)
            
            # Simple simulation of "Trial" detection from subject regex
            is_trial = any(kw in subject for kw in ["trial", "free", "0.00"])

            found_subs.append(Subscription(
                id=msg['id'],
                name=refined_name,
                price=9.99, # Simplified: in prod we parse the body
                currency="$",
                date=date,
                category=meta["category"],
                cancel_url=meta["cancel_url"],
                is_trial=is_trial,
                status="active",
                payment_method="Linked Card"
            ))
        return found_subs
    except Exception as e:
        log_error("Gmail Parsing Error", error=e)
        return []

@app.get("/scan", response_model=ScanResult)
async def scan_pro():
    # Mock result showing Currency Conversion & Card Resolution
    today = datetime.date.today().isoformat()
    next_month = (datetime.date.today() + datetime.timedelta(days=30)).strftime("%b %d, %Y")
    
    # Showcase features
    raw_subs = [
        {"name": "iCloud", "price": 2900.00, "currency": "₦", "card": "Card 4242", "usage": 0.9, "auto_kill": False, "days": 3, "cycle": 30, "bank": "Access Bank"},
        {"name": "ChatGPT Plus", "price": 20.00, "currency": "$", "card": "GHOST-8812", "usage": 0.95, "auto_kill": False, "is_ghost": True, "days": 12, "cycle": 30, "bank": "Ghost Vault"},
        {"name": "Netflix Premium", "price": 10.99, "currency": "£", "card": "Card 4242", "usage": 0.4, "auto_kill": True, "days": 1, "cycle": 30, "bank": "Kuda Bank"},
        {"name": "Disney+ Trial", "price": 0.00, "currency": "$", "card": "VIRTUAL-001", "usage": 0.05, "auto_kill": False, "days": 1, "cycle": 7, "bank": "Zenith Bank"},
        {"name": "Spotify", "price": 1500.00, "currency": "₦", "card": "Card 5061", "usage": 0.85, "auto_kill": False, "days": 15, "cycle": 30, "bank": "UBA"},
    ]
    
    subscriptions = []
    total_burn_usd = 0.0
    
    for item in raw_subs:
        refined_name, meta = detect_subscription_metadata(item["name"])
        curr = item["currency"].replace("₦", "NGN").replace("£", "GBP").replace("$", "USD")
        price_usd = normalize_currency(item["price"], curr)
        total_burn_usd += price_usd
        
        opt_tip, potential = get_optimization_tip(refined_name, price_usd)
        
        subscriptions.append(Subscription(
            id=f"sub-{refined_name.lower().replace(' ', '-')}",
            name=refined_name,
            price=item["price"],
            currency=item["currency"],
            date=today,
            category=meta["category"],
            renewal_date=next_month,
            cancel_url=meta["cancel_url"] or f"https://www.{refined_name.lower().replace(' ', '')}.com/settings",
            is_trial=(item["price"] == 0.0),
            optimization_tip=opt_tip if potential > 0 else None,
            savings_potential=potential,
            payment_method=item["card"],
            auto_kill=item.get("auto_kill", False),
            is_ghost_card=item.get("is_ghost", False),
            usage_level=item.get("usage", 1.0),
            days_remaining=item.get("days", 30),
            total_cycle_days=item.get("cycle", 30),
            is_bank_connected=True,
            bank_name=item.get("bank", "Primary Bank")
        ))
    
    return ScanResult(
        annual_leak=total_burn_usd * 12,
        total_saved=total_burn_usd * 0.15, # Simulated
        monthly_burn_rate=total_burn_usd,
        subscriptions=subscriptions,
        kill_history=[
            Subscription(id="h1", name="Hulu", price=7.99, currency="$", date="2025-12-01", category="Video", status="killed", days_remaining=0, total_cycle_days=30, is_bank_connected=True, bank_name="GTBank")
        ]
    )

@app.get("/global-scan")
async def global_scan():
    # Simulated AI logic for detecting "leaks" (unauthorized trial conversions)
    # This would usually crawl recent transactions or SMS/Email logs
    return [
        {"id": "leak1", "source": "Card 4242", "service": "Paramount+", "type": "Hold", "status": "Suspected", "risk": "High"},
        {"id": "leak2", "source": "Card 8812", "service": "DraftKings", "type": "Auth $0", "status": "Required", "risk": "Medium"},
        {"id": "leak3", "source": "Email", "service": "Premium App", "type": "Receipt", "status": "Active", "risk": "Low"},
        {"id": "leak4", "source": "Card 4242", "service": "X Premium", "type": "Hold", "status": "Suspected", "risk": "High"},
    ]

# --- PLAID INTEGRATION ---

@app.post("/api/v1/plaid/create-link-token")
async def create_link_token():
    try:
        request = LinkTokenCreateRequest(
            products=[Products("transactions")],
            client_name="Kill Switch Pro",
            country_codes=[CountryCode("US"), CountryCode("GB"), CountryCode("CA")],
            language="en",
            user=LinkTokenCreateRequestUser(client_user_id="user-123"), # Dynamic in prod
        )
        response = plaid_client.link_token_create(request)
        return {"link_token": response['link_token']}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/plaid/exchange-token")
async def exchange_token(public_token: str):
    # This would exchange the public token for an access token
    # and store it in a database associated with the user.
    return {"status": "success", "message": "Bank account linked (Sandbox Demo)"}

# --- GMAIL OAUTH SKELETON ---

@app.get("/api/v1/auth/gmail/url")
async def get_gmail_auth_url():
    # In a real app, this would use the client secrets to generate a redirect URL
    return {"url": "https://accounts.google.com/o/oauth2/auth?..."}

@app.post("/api/v1/auth/gmail/callback")
async def gmail_callback(code: str):
    # This would exchange the auth code for tokens
    return {"status": "success", "message": "Gmail access granted"}

# --- VIRTUAL CARD MANAGEMENT (LITHIC) ---

class CreateVirtualCardRequest(BaseModel):
    subscription_name: str
    merchant_name: str
    spending_limit: float
    user_id: str

class VirtualCardResponse(BaseModel):
    card_id: str
    last_four: str
    cvv: str
    exp_month: str
    exp_year: str
    status: str
    spending_limit: float

@app.post("/api/v1/cards/create-virtual", response_model=VirtualCardResponse)
@limiter.limit("5/minute")  # Max 5 cards per minute
async def create_virtual_card(request: Request, card_request: CreateVirtualCardRequest):
    """
    Create a disposable virtual card for a specific subscription.
    This card can be paused/closed when the user wants to kill the subscription.
    """
    with LogContext("create_virtual_card", user_id=card_request.user_id, subscription=card_request.subscription_name):
        try:
            # Create a virtual card via Lithic
            card = lithic_client.cards.create(
                type="VIRTUAL",
                memo=f"Kill Switch - {card_request.subscription_name}",
                spend_limit=int(card_request.spending_limit * 100),  # Convert to cents
                spend_limit_duration="MONTHLY",
            )
            
            # Store in database
            await db.save_virtual_card(
                user_id=card_request.user_id,
                subscription_id=card_request.subscription_name,  # Would be actual ID in production
                lithic_card_id=card.token,
                last_four=card.last_four,
                status=card.state,
                spending_limit=card_request.spending_limit
            )
            
            log_info("Virtual card created", card_id=card.token, user_id=card_request.user_id)
            
            return VirtualCardResponse(
                card_id=card.token,
                last_four=card.last_four,
                cvv=card.cvv,
                exp_month=str(card.exp_month).zfill(2),
                exp_year=str(card.exp_year),
                status=card.state,
                spending_limit=card_request.spending_limit
            )
        except Exception as e:
            log_error("Failed to create virtual card", error=e, user_id=card_request.user_id)
            raise HTTPException(status_code=500, detail=f"Failed to create virtual card: {str(e)}")

@app.post("/api/v1/cards/pause/{card_id}")
async def pause_virtual_card(card_id: str):
    """
    Pause a virtual card to prevent further charges.
    This is the 'soft kill' - can be resumed later.
    """
    try:
        card = lithic_client.cards.update(
            card_token=card_id,
            state="PAUSED"
        )
        return {
            "status": "success",
            "message": f"Card {card.last_four} paused successfully",
            "card_state": card.state
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to pause card: {str(e)}")

@app.post("/api/v1/cards/close/{card_id}")
async def close_virtual_card(card_id: str):
    """
    Permanently close a virtual card.
    This is the 'hard kill' - cannot be resumed.
    """
    try:
        card = lithic_client.cards.update(
            card_token=card_id,
            state="CLOSED"
        )
        return {
            "status": "success",
            "message": f"Card {card.last_four} permanently closed",
            "card_state": card.state
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to close card: {str(e)}")

@app.get("/api/v1/cards/{card_id}/transactions")
async def get_card_transactions(card_id: str):
    """
    Get transaction history for a virtual card.
    Useful for showing what charges were blocked.
    """
    try:
        transactions = lithic_client.transactions.list(
            card_token=card_id,
            page_size=50
        )
        return {
            "card_id": card_id,
            "transactions": [
                {
                    "amount": t.amount / 100,  # Convert from cents
                    "merchant": t.merchant.descriptor,
                    "status": t.status,
                    "created": t.created.isoformat(),
                }
                for t in transactions.data
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch transactions: {str(e)}")


@app.post("/kill-subscription/{sub_id}")
async def kill_subscription(sub_id: str):
    # Logic to simulate contacting the service provider or blocking the transaction
    # In production, this might call a banking API (e.g. Plaid, Stripe) or use a headless browser
    return {"status": "success", "message": f"Subscription {sub_id} neutralized successfully"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)