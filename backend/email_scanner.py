"""
Enhanced Email Scanner for Kill Switch
Detects subscriptions, trials, renewals, and cancellation links from Gmail
"""

import re
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Tuple
import base64
from email.utils import parsedate_to_datetime

# Enhanced subscription detection patterns
TRIAL_PATTERNS = [
    r'trial\s+(?:period\s+)?(?:ends?|expires?|ending)',
    r'free\s+trial',
    r'(?:your\s+)?trial\s+(?:will\s+)?(?:end|expire)',
    r'trial\s+conversion',
    r'(?:trial\s+)?(?:ends?|expires?)\s+(?:in\s+)?(\d+)\s+days?',
    r'(?:free\s+)?trial\s+(?:period\s+)?(?:of\s+)?(\d+)\s+days?',
]

PRICE_PATTERNS = [
    r'[\$£€₦]\s*(\d+(?:\.\d{2})?)',
    r'(\d+(?:\.\d{2})?)\s*(?:USD|GBP|EUR|NGN)',
    r'(?:total|amount|price|cost):\s*[\$£€₦]?\s*(\d+(?:\.\d{2})?)',
    r'(?:billed|charged)\s+[\$£€₦]?\s*(\d+(?:\.\d{2})?)',
]

RENEWAL_PATTERNS = [
    r'(?:next\s+)?(?:bill|charge|payment|renewal)\s+(?:date|on):\s*([A-Za-z]+\s+\d{1,2},?\s+\d{4})',
    r'renew(?:s|al)?\s+(?:on\s+)?([A-Za-z]+\s+\d{1,2},?\s+\d{4})',
    r'(?:subscription\s+)?renew(?:s|al)?\s+([A-Za-z]+\s+\d{1,2})',
    r'(?:your\s+)?(?:next\s+)?payment\s+(?:is\s+)?(?:due\s+)?(?:on\s+)?([A-Za-z]+\s+\d{1,2})',
]

CANCELLATION_PATTERNS = [
    r'(?:cancel|unsubscribe|manage)\s+(?:your\s+)?(?:subscription|membership)',
    r'https?://[^\s]+(?:cancel|unsubscribe|settings|account|manage)',
]

# Service-specific cancellation URLs
KNOWN_CANCEL_URLS = {
    'netflix': 'https://www.netflix.com/cancelplan',
    'spotify': 'https://www.spotify.com/account/subscription/',
    'apple': 'https://support.apple.com/en-us/HT202039',
    'amazon': 'https://www.amazon.com/gp/primecentral',
    'disney': 'https://www.disneyplus.com/account',
    'hulu': 'https://secure.hulu.com/account',
    'youtube': 'https://www.youtube.com/paid_memberships',
    'chatgpt': 'https://platform.openai.com/account/billing',
    'github': 'https://github.com/settings/billing',
    'adobe': 'https://account.adobe.com/plans',
}


class EnhancedEmailScanner:
    """Advanced email scanner with trial detection and cancellation link extraction"""
    
    @staticmethod
    def extract_price(text: str) -> Tuple[Optional[float], Optional[str]]:
        """Extract price and currency from email text"""
        text = text.lower()
        
        for pattern in PRICE_PATTERNS:
            match = re.search(pattern, text)
            if match:
                try:
                    price = float(match.group(1))
                    # Detect currency
                    currency = '$'  # default
                    if '£' in text or 'gbp' in text:
                        currency = '£'
                    elif '€' in text or 'eur' in text:
                        currency = '€'
                    elif '₦' in text or 'ngn' in text or 'naira' in text:
                        currency = '₦'
                    return price, currency
                except (ValueError, IndexError):
                    continue
        
        return None, None
    
    @staticmethod
    def detect_trial(subject: str, body: str) -> Tuple[bool, Optional[int]]:
        """
        Detect if this is a trial subscription
        Returns: (is_trial, days_remaining)
        """
        combined_text = f"{subject} {body}".lower()
        
        # Check for trial keywords
        is_trial = any(keyword in combined_text for keyword in [
            'trial', 'free trial', 'trial period', 'trial ends', 'trial expires'
        ])
        
        if not is_trial:
            return False, None
        
        # Try to extract days remaining
        for pattern in TRIAL_PATTERNS:
            match = re.search(pattern, combined_text)
            if match:
                # Try to extract number of days
                days_match = re.search(r'(\d+)\s+days?', match.group(0))
                if days_match:
                    return True, int(days_match.group(1))
        
        # Default to 7 days if we can't determine
        return True, 7
    
    @staticmethod
    def extract_renewal_date(subject: str, body: str) -> Optional[str]:
        """Extract the next renewal/billing date"""
        combined_text = f"{subject} {body}"
        
        for pattern in RENEWAL_PATTERNS:
            match = re.search(pattern, combined_text, re.IGNORECASE)
            if match:
                try:
                    date_str = match.group(1)
                    # Try to parse the date
                    # This is a simplified version - production would use dateutil
                    return date_str
                except (IndexError, ValueError):
                    continue
        
        return None
    
    @staticmethod
    def extract_cancellation_link(service_name: str, body: str) -> Optional[str]:
        """Extract cancellation/management link from email"""
        service_lower = service_name.lower()
        
        # Check known URLs first
        for keyword, url in KNOWN_CANCEL_URLS.items():
            if keyword in service_lower:
                return url
        
        # Try to find links in email body
        url_pattern = r'https?://[^\s<>"]+(?:cancel|unsubscribe|settings|account|manage)[^\s<>"]*'
        matches = re.findall(url_pattern, body, re.IGNORECASE)
        
        if matches:
            return matches[0]
        
        # Fallback: construct likely URL
        service_clean = re.sub(r'[^a-z0-9]', '', service_lower)
        return f"https://www.{service_clean}.com/account/settings"
    
    @staticmethod
    def detect_price_change(subject: str, body: str) -> Tuple[bool, Optional[float], Optional[float]]:
        """
        Detect if this email announces a price change
        Returns: (has_change, old_price, new_price)
        """
        combined_text = f"{subject} {body}".lower()
        
        price_change_keywords = [
            'price increase', 'price change', 'new price', 'rate change',
            'subscription cost', 'price update', 'increasing to'
        ]
        
        has_change = any(keyword in combined_text for keyword in price_change_keywords)
        
        if not has_change:
            return False, None, None
        
        # Try to extract old and new prices
        prices = []
        for pattern in PRICE_PATTERNS:
            matches = re.findall(pattern, combined_text)
            prices.extend([float(m) if isinstance(m, str) else float(m[0]) for m in matches])
        
        if len(prices) >= 2:
            return True, min(prices), max(prices)
        
        return True, None, None
    
    @staticmethod
    def categorize_email_type(subject: str, body: str) -> str:
        """Determine the type of subscription email"""
        combined = f"{subject} {body}".lower()
        
        if any(kw in combined for kw in ['trial end', 'trial expir', 'trial convert']):
            return 'trial_ending'
        elif any(kw in combined for kw in ['receipt', 'payment received', 'invoice', 'charged']):
            return 'payment_confirmation'
        elif any(kw in combined for kw in ['renewal', 'renew', 'upcoming charge']):
            return 'renewal_reminder'
        elif any(kw in combined for kw in ['welcome', 'getting started', 'thank you for subscribing']):
            return 'new_subscription'
        elif any(kw in combined for kw in ['price increase', 'price change', 'new rate']):
            return 'price_change'
        elif any(kw in combined for kw in ['cancel', 'unsubscribe']):
            return 'cancellation'
        else:
            return 'general'
    
    @staticmethod
    def extract_payment_method(body: str) -> Optional[str]:
        """Extract payment method information"""
        # Look for card patterns
        card_pattern = r'(?:card|visa|mastercard|amex).*?(\d{4})'
        match = re.search(card_pattern, body.lower())
        if match:
            return f"Card ****{match.group(1)}"
        
        # Look for PayPal
        if 'paypal' in body.lower():
            return "PayPal"
        
        # Look for bank account
        if any(kw in body.lower() for kw in ['bank account', 'direct debit', 'ach']):
            return "Bank Account"
        
        return None


def calculate_days_until(date_str: str) -> int:
    """Calculate days until a given date string"""
    try:
        # This is simplified - production would use proper date parsing
        # For now, return a mock value
        return 7
    except:
        return 30


def should_alert_user(email_type: str, days_remaining: Optional[int]) -> Tuple[bool, str]:
    """
    Determine if user should be alerted about this subscription
    Returns: (should_alert, alert_reason)
    """
    if email_type == 'trial_ending':
        if days_remaining and days_remaining <= 3:
            return True, f"Trial ends in {days_remaining} day{'s' if days_remaining != 1 else ''}!"
        elif days_remaining and days_remaining <= 7:
            return True, f"Trial ends soon ({days_remaining} days)"
    
    elif email_type == 'price_change':
        return True, "Price increase detected"
    
    elif email_type == 'renewal_reminder':
        return True, "Renewal coming up"
    
    return False, ""
