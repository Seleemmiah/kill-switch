"""
Notification Service for Kill Switch
Handles push notifications, email alerts, and in-app notifications
"""

from typing import List, Dict, Optional
from datetime import datetime, timedelta
from enum import Enum


class NotificationType(Enum):
    TRIAL_ENDING_SOON = "trial_ending_soon"
    TRIAL_ENDING_TODAY = "trial_ending_today"
    RENEWAL_REMINDER = "renewal_reminder"
    LOW_USAGE_WARNING = "low_usage_warning"
    PRICE_INCREASE = "price_increase"
    FORGOTTEN_SUBSCRIPTION = "forgotten_subscription"
    DUPLICATE_SUBSCRIPTION = "duplicate_subscription"
    PAYMENT_FAILED = "payment_failed"


class NotificationPriority(Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"


class Notification:
    def __init__(
        self,
        notification_type: NotificationType,
        title: str,
        message: str,
        subscription_id: str,
        subscription_name: str,
        priority: NotificationPriority = NotificationPriority.MEDIUM,
        action_url: Optional[str] = None,
        action_label: Optional[str] = None,
        metadata: Optional[Dict] = None
    ):
        self.type = notification_type
        self.title = title
        self.message = message
        self.subscription_id = subscription_id
        self.subscription_name = subscription_name
        self.priority = priority
        self.action_url = action_url
        self.action_label = action_label
        self.metadata = metadata or {}
        self.created_at = datetime.now()
        self.is_read = False
    
    def to_dict(self) -> Dict:
        return {
            "id": f"notif_{self.subscription_id}_{int(self.created_at.timestamp())}",
            "type": self.type.value,
            "title": self.title,
            "message": self.message,
            "subscription_id": self.subscription_id,
            "subscription_name": self.subscription_name,
            "priority": self.priority.value,
            "action_url": self.action_url,
            "action_label": self.action_label,
            "metadata": self.metadata,
            "created_at": self.created_at.isoformat(),
            "is_read": self.is_read
        }


class NotificationService:
    """Service for managing subscription-related notifications"""
    
    def __init__(self):
        # In production, this would connect to Firebase Cloud Messaging,
        # Apple Push Notification service, or a service like OneSignal
        self.notifications_queue: List[Notification] = []
    
    def check_trial_alerts(self, subscription: Dict) -> Optional[Notification]:
        """Check if a trial subscription needs an alert"""
        if not subscription.get('is_trial'):
            return None
        
        days_remaining = subscription.get('days_remaining', 30)
        name = subscription.get('name', 'Unknown')
        sub_id = subscription.get('id', '')
        cancel_url = subscription.get('cancel_url')
        
        # 3-day warning
        if days_remaining == 3:
            return Notification(
                notification_type=NotificationType.TRIAL_ENDING_SOON,
                title=f"⚠️ {name} Trial Ending Soon",
                message=f"Your {name} free trial ends in 3 days. Cancel now to avoid charges.",
                subscription_id=sub_id,
                subscription_name=name,
                priority=NotificationPriority.HIGH,
                action_url=cancel_url,
                action_label="Cancel Now",
                metadata={"days_remaining": days_remaining}
            )
        
        # 1-day warning
        elif days_remaining == 1:
            return Notification(
                notification_type=NotificationType.TRIAL_ENDING_TODAY,
                title=f"🚨 {name} Trial Ends Tomorrow!",
                message=f"Your {name} trial ends tomorrow. You'll be charged if you don't cancel.",
                subscription_id=sub_id,
                subscription_name=name,
                priority=NotificationPriority.URGENT,
                action_url=cancel_url,
                action_label="Cancel Immediately",
                metadata={"days_remaining": days_remaining}
            )
        
        # Same day warning
        elif days_remaining == 0:
            return Notification(
                notification_type=NotificationType.TRIAL_ENDING_TODAY,
                title=f"🔥 {name} Trial Ends TODAY!",
                message=f"URGENT: Your {name} trial ends today. Cancel NOW to avoid charges!",
                subscription_id=sub_id,
                subscription_name=name,
                priority=NotificationPriority.URGENT,
                action_url=cancel_url,
                action_label="CANCEL NOW",
                metadata={"days_remaining": 0}
            )
        
        return None
    
    def check_renewal_reminder(self, subscription: Dict) -> Optional[Notification]:
        """Check if a renewal reminder is needed"""
        days_remaining = subscription.get('days_remaining', 30)
        name = subscription.get('name', 'Unknown')
        sub_id = subscription.get('id', '')
        price = subscription.get('price', 0)
        currency = subscription.get('currency', '$')
        
        # 3-day renewal reminder
        if days_remaining == 3 and not subscription.get('is_trial'):
            return Notification(
                notification_type=NotificationType.RENEWAL_REMINDER,
                title=f"💳 {name} Renews in 3 Days",
                message=f"You'll be charged {currency}{price} in 3 days for {name}.",
                subscription_id=sub_id,
                subscription_name=name,
                priority=NotificationPriority.MEDIUM,
                metadata={"days_remaining": days_remaining, "amount": price}
            )
        
        return None
    
    def check_low_usage(self, subscription: Dict) -> Optional[Notification]:
        """Alert user about low-usage subscriptions"""
        usage_level = subscription.get('usage_level', 1.0)
        name = subscription.get('name', 'Unknown')
        sub_id = subscription.get('id', '')
        price = subscription.get('price', 0)
        currency = subscription.get('currency', '$')
        
        # Alert if usage is below 25%
        if usage_level < 0.25:
            potential_savings = price * 12  # Annual savings
            return Notification(
                notification_type=NotificationType.LOW_USAGE_WARNING,
                title=f"💡 Barely Using {name}?",
                message=f"You've barely used {name} this month. Cancel and save {currency}{potential_savings}/year.",
                subscription_id=sub_id,
                subscription_name=name,
                priority=NotificationPriority.LOW,
                action_label="Review Subscription",
                metadata={"usage_level": usage_level, "potential_savings": potential_savings}
            )
        
        return None
    
    def check_price_increase(self, subscription: Dict) -> Optional[Notification]:
        """Alert about price increases"""
        if subscription.get('price_increased'):
            name = subscription.get('name', 'Unknown')
            sub_id = subscription.get('id', '')
            old_price = subscription.get('old_price', 0)
            new_price = subscription.get('price', 0)
            currency = subscription.get('currency', '$')
            
            increase = new_price - old_price
            increase_pct = (increase / old_price * 100) if old_price > 0 else 0
            
            return Notification(
                notification_type=NotificationType.PRICE_INCREASE,
                title=f"📈 {name} Price Increased",
                message=f"{name} increased from {currency}{old_price} to {currency}{new_price} (+{increase_pct:.0f}%).",
                subscription_id=sub_id,
                subscription_name=name,
                priority=NotificationPriority.HIGH,
                metadata={"old_price": old_price, "new_price": new_price, "increase": increase}
            )
        
        return None
    
    def check_forgotten_subscription(self, subscription: Dict) -> Optional[Notification]:
        """Detect subscriptions user might have forgotten about"""
        # Check if subscription hasn't been viewed in app for 60+ days
        last_viewed = subscription.get('last_viewed_days_ago', 0)
        name = subscription.get('name', 'Unknown')
        sub_id = subscription.get('id', '')
        price = subscription.get('price', 0)
        currency = subscription.get('currency', '$')
        
        if last_viewed > 60:
            return Notification(
                notification_type=NotificationType.FORGOTTEN_SUBSCRIPTION,
                title=f"🤔 Still Need {name}?",
                message=f"You haven't checked {name} in {last_viewed} days. Still using it?",
                subscription_id=sub_id,
                subscription_name=name,
                priority=NotificationPriority.MEDIUM,
                action_label="Review",
                metadata={"last_viewed_days": last_viewed, "monthly_cost": price}
            )
        
        return None
    
    def generate_all_notifications(self, subscriptions: List[Dict]) -> List[Notification]:
        """Generate all relevant notifications for a list of subscriptions"""
        notifications = []
        
        for sub in subscriptions:
            # Check all notification types
            checks = [
                self.check_trial_alerts(sub),
                self.check_renewal_reminder(sub),
                self.check_low_usage(sub),
                self.check_price_increase(sub),
                self.check_forgotten_subscription(sub),
            ]
            
            # Add non-None notifications
            notifications.extend([n for n in checks if n is not None])
        
        # Sort by priority (URGENT first)
        priority_order = {
            NotificationPriority.URGENT: 0,
            NotificationPriority.HIGH: 1,
            NotificationPriority.MEDIUM: 2,
            NotificationPriority.LOW: 3,
        }
        notifications.sort(key=lambda n: priority_order[n.priority])
        
        return notifications
    
    def get_notification_summary(self, notifications: List[Notification]) -> Dict:
        """Get a summary of notifications by type and priority"""
        summary = {
            "total": len(notifications),
            "urgent": sum(1 for n in notifications if n.priority == NotificationPriority.URGENT),
            "high": sum(1 for n in notifications if n.priority == NotificationPriority.HIGH),
            "by_type": {}
        }
        
        for notif in notifications:
            type_key = notif.type.value
            summary["by_type"][type_key] = summary["by_type"].get(type_key, 0) + 1
        
        return summary


# Singleton instance
notification_service = NotificationService()
