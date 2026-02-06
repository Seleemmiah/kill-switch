"""
Celery background tasks for periodic operations.
Handles Gmail scanning, trial expiration checks, and analytics.
"""
import os
from celery import Celery
from celery.schedules import crontab
from dotenv import load_dotenv

load_dotenv()

# Configure Celery
redis_url = os.getenv('REDIS_URL', 'redis://localhost:6379')
celery_app = Celery(
    'kill_switch',
    broker=redis_url,
    backend=redis_url
)

# Celery configuration
celery_app.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
    task_track_started=True,
    task_time_limit=300,  # 5 minutes max
    worker_prefetch_multiplier=1,
)

# Periodic task schedule
celery_app.conf.beat_schedule = {
    'scan-all-users-gmail': {
        'task': 'tasks.scan_all_users',
        'schedule': crontab(hour=2, minute=0),  # 2 AM daily
    },
    'check-trial-expirations': {
        'task': 'tasks.check_trials',
        'schedule': crontab(hour=10, minute=0),  # 10 AM daily
    },
    'update-analytics': {
        'task': 'tasks.update_analytics',
        'schedule': crontab(minute=0),  # Every hour
    },
}

# Tasks
@celery_app.task(name='tasks.scan_all_users')
def scan_all_users():
    """Scan Gmail for all users to detect new subscriptions"""
    from database import db
    from logging_config import log_info, log_error
    
    try:
        log_info("Starting Gmail scan for all users")
        
        # This would iterate through all users
        # For now, it's a placeholder
        
        log_info("Gmail scan completed")
        return {"status": "success", "users_scanned": 0}
    except Exception as e:
        log_error("Gmail scan failed", error=e)
        raise

@celery_app.task(name='tasks.check_trials')
def check_trial_expirations():
    """Check for expiring trials and notify users"""
    from database import db
    from logging_config import log_info, log_error
    import datetime
    
    try:
        log_info("Checking trial expirations")
        
        # Get subscriptions with trials ending soon
        # Send push notifications
        
        log_info("Trial check completed")
        return {"status": "success", "notifications_sent": 0}
    except Exception as e:
        log_error("Trial check failed", error=e)
        raise

@celery_app.task(name='tasks.update_analytics')
def update_analytics():
    """Update analytics and metrics"""
    from database import db
    from cache import cache
    from logging_config import log_info, log_error
    
    try:
        log_info("Updating analytics")
        
        # Calculate platform-wide metrics
        metrics = {
            "total_users": 0,
            "total_subscriptions_killed": 0,
            "total_savings": 0.0,
            "active_virtual_cards": 0,
        }
        
        # Cache metrics
        cache.set("platform:metrics", metrics, ttl=3600)
        
        log_info("Analytics updated", **metrics)
        return metrics
    except Exception as e:
        log_error("Analytics update failed", error=e)
        raise

@celery_app.task(name='tasks.scan_user_gmail')
def scan_user_gmail(user_id: str):
    """Scan Gmail for a specific user"""
    from logging_config import log_info, log_error, LogContext
    
    with LogContext("scan_user_gmail", user_id=user_id):
        try:
            # Gmail scanning logic here
            return {"status": "success", "subscriptions_found": 0}
        except Exception as e:
            log_error("User Gmail scan failed", error=e, user_id=user_id)
            raise

@celery_app.task(name='tasks.process_webhook')
def process_webhook(event_type: str, payload: dict):
    """Process webhooks from Lithic asynchronously"""
    from database import db
    from logging_config import log_info, log_error
    
    try:
        log_info("Processing webhook", event_type=event_type)
        
        if event_type == "transaction.created":
            # Save transaction to database
            card_id = payload.get('card_token')
            amount = payload.get('amount', 0) / 100
            merchant = payload.get('merchant', {}).get('descriptor', 'Unknown')
            status = payload.get('status', 'PENDING')
            
            # This would save to database
            log_info("Transaction processed", card_id=card_id, amount=amount)
        
        elif event_type == "card.state_changed":
            # Update card status
            card_id = payload.get('token')
            new_state = payload.get('state')
            
            log_info("Card state updated", card_id=card_id, state=new_state)
        
        return {"status": "processed"}
    except Exception as e:
        log_error("Webhook processing failed", error=e, event_type=event_type)
        raise

if __name__ == '__main__':
    # Run worker: celery -A tasks worker --loglevel=info
    # Run beat: celery -A tasks beat --loglevel=info
    celery_app.start()
