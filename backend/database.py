"""
Database service using Supabase for persistent storage.
Replaces in-memory dictionaries with real database.
"""
import os
from typing import List, Optional, Dict, Any
from supabase import create_client, Client
from dotenv import load_dotenv
import json
from datetime import datetime

load_dotenv()

class DatabaseService:
    def __init__(self):
        supabase_url = os.getenv('SUPABASE_URL')
        supabase_key = os.getenv('SUPABASE_KEY')
        
        if supabase_url and supabase_key:
            self.client: Client = create_client(supabase_url, supabase_key)
            self.enabled = True
        else:
            self.client = None
            self.enabled = False
            print("⚠️  Supabase not configured - using in-memory storage")
    
    # --- USERS ---
    
    async def create_user(self, user_id: str, email: str, metadata: Dict = None) -> Dict:
        """Create or update user profile"""
        if not self.enabled:
            return {"id": user_id, "email": email}
        
        data = {
            "id": user_id,
            "email": email,
            "metadata": metadata or {},
            "created_at": datetime.utcnow().isoformat()
        }
        
        result = self.client.table('users').upsert(data).execute()
        return result.data[0] if result.data else data
    
    async def get_user(self, user_id: str) -> Optional[Dict]:
        """Get user by ID"""
        if not self.enabled:
            return None
        
        result = self.client.table('users').select("*").eq('id', user_id).execute()
        return result.data[0] if result.data else None
    
    # --- SUBSCRIPTIONS ---
    
    async def create_subscription(
        self, 
        user_id: str, 
        name: str, 
        price: float,
        currency: str = "$",
        category: str = "General",
        virtual_card_id: Optional[str] = None,
        metadata: Dict = None
    ) -> Dict:
        """Create a new subscription"""
        if not self.enabled:
            return {
                "id": f"sub_{name.lower().replace(' ', '_')}",
                "user_id": user_id,
                "name": name,
                "price": price
            }
        
        data = {
            "user_id": user_id,
            "name": name,
            "price": price,
            "currency": currency,
            "category": category,
            "status": "active",
            "virtual_card_id": virtual_card_id,
            "metadata": metadata or {},
            "detected_at": datetime.utcnow().isoformat()
        }
        
        result = self.client.table('subscriptions').insert(data).execute()
        return result.data[0] if result.data else data
    
    async def get_user_subscriptions(self, user_id: str, status: str = "active") -> List[Dict]:
        """Get all subscriptions for a user"""
        if not self.enabled:
            return []
        
        query = self.client.table('subscriptions').select("*").eq('user_id', user_id)
        
        if status:
            query = query.eq('status', status)
        
        result = query.execute()
        return result.data if result.data else []
    
    async def update_subscription(self, subscription_id: str, updates: Dict) -> Dict:
        """Update subscription details"""
        if not self.enabled:
            return updates
        
        result = self.client.table('subscriptions').update(updates).eq('id', subscription_id).execute()
        return result.data[0] if result.data else updates
    
    async def kill_subscription(self, subscription_id: str, user_id: str) -> Dict:
        """Mark subscription as killed and create kill history"""
        if not self.enabled:
            return {"status": "killed"}
        
        # Get subscription details
        sub_result = self.client.table('subscriptions').select("*").eq('id', subscription_id).execute()
        if not sub_result.data:
            raise ValueError("Subscription not found")
        
        subscription = sub_result.data[0]
        
        # Update status
        self.client.table('subscriptions').update({
            "status": "killed",
            "killed_at": datetime.utcnow().isoformat()
        }).eq('id', subscription_id).execute()
        
        # Create kill history
        annual_savings = subscription['price'] * 12
        kill_data = {
            "user_id": user_id,
            "subscription_id": subscription_id,
            "subscription_name": subscription['name'],
            "monthly_cost": subscription['price'],
            "annual_savings": annual_savings,
            "killed_at": datetime.utcnow().isoformat()
        }
        
        self.client.table('kill_history').insert(kill_data).execute()
        
        return {
            "status": "killed",
            "savings": annual_savings,
            "subscription": subscription
        }
    
    # --- VIRTUAL CARDS ---
    
    async def save_virtual_card(
        self,
        user_id: str,
        subscription_id: str,
        lithic_card_id: str,
        last_four: str,
        status: str = "OPEN",
        spending_limit: float = 0.0
    ) -> Dict:
        """Save virtual card mapping"""
        if not self.enabled:
            return {"id": lithic_card_id}
        
        data = {
            "user_id": user_id,
            "subscription_id": subscription_id,
            "lithic_card_id": lithic_card_id,
            "last_four": last_four,
            "status": status,
            "spending_limit": spending_limit,
            "created_at": datetime.utcnow().isoformat()
        }
        
        result = self.client.table('virtual_cards').insert(data).execute()
        return result.data[0] if result.data else data
    
    async def get_virtual_card(self, card_id: str) -> Optional[Dict]:
        """Get virtual card by Lithic card ID"""
        if not self.enabled:
            return None
        
        result = self.client.table('virtual_cards').select("*").eq('lithic_card_id', card_id).execute()
        return result.data[0] if result.data else None
    
    async def update_card_status(self, card_id: str, status: str) -> Dict:
        """Update virtual card status"""
        if not self.enabled:
            return {"status": status}
        
        result = self.client.table('virtual_cards').update({
            "status": status,
            "updated_at": datetime.utcnow().isoformat()
        }).eq('lithic_card_id', card_id).execute()
        
        return result.data[0] if result.data else {"status": status}
    
    # --- TRANSACTIONS ---
    
    async def save_transaction(
        self,
        card_id: str,
        amount: float,
        merchant: str,
        status: str,
        transaction_id: str,
        metadata: Dict = None
    ) -> Dict:
        """Save transaction record"""
        if not self.enabled:
            return {"id": transaction_id}
        
        data = {
            "card_id": card_id,
            "transaction_id": transaction_id,
            "amount": amount,
            "merchant": merchant,
            "status": status,
            "metadata": metadata or {},
            "created_at": datetime.utcnow().isoformat()
        }
        
        result = self.client.table('transactions').insert(data).execute()
        return result.data[0] if result.data else data
    
    async def get_card_transactions(self, card_id: str, limit: int = 50) -> List[Dict]:
        """Get transactions for a card"""
        if not self.enabled:
            return []
        
        result = self.client.table('transactions')\
            .select("*")\
            .eq('card_id', card_id)\
            .order('created_at', desc=True)\
            .limit(limit)\
            .execute()
        
        return result.data if result.data else []
    
    # --- ANALYTICS ---
    
    async def get_user_stats(self, user_id: str) -> Dict:
        """Get user statistics"""
        if not self.enabled:
            return {
                "total_subscriptions": 0,
                "active_subscriptions": 0,
                "killed_subscriptions": 0,
                "total_savings": 0.0,
                "monthly_spend": 0.0
            }
        
        # Get active subscriptions
        active = await self.get_user_subscriptions(user_id, "active")
        killed = await self.get_user_subscriptions(user_id, "killed")
        
        # Calculate monthly spend
        monthly_spend = sum(sub['price'] for sub in active)
        
        # Get total savings from kill history
        savings_result = self.client.table('kill_history')\
            .select("annual_savings")\
            .eq('user_id', user_id)\
            .execute()
        
        total_savings = sum(item['annual_savings'] for item in savings_result.data) if savings_result.data else 0.0
        
        return {
            "total_subscriptions": len(active) + len(killed),
            "active_subscriptions": len(active),
            "killed_subscriptions": len(killed),
            "total_savings": total_savings,
            "monthly_spend": monthly_spend,
            "annual_leak": monthly_spend * 12
        }

# Global instance
db = DatabaseService()
