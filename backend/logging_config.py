"""
Centralized logging and error handling configuration.
Integrates Sentry for error tracking and structured JSON logging.
"""
import os
import logging
import sentry_sdk
from pythonjsonlogger import jsonlogger
from dotenv import load_dotenv
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.httpx import HttpxIntegration

load_dotenv()

def setup_logging():
    """Configure structured JSON logging"""
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    
    # Remove existing handlers
    logger.handlers = []
    
    # JSON formatter
    logHandler = logging.StreamHandler()
    formatter = jsonlogger.JsonFormatter(
        '%(asctime)s %(name)s %(levelname)s %(message)s',
        rename_fields={
            "asctime": "timestamp",
            "levelname": "level",
            "name": "logger"
        }
    )
    logHandler.setFormatter(formatter)
    logger.addHandler(logHandler)
    
    return logger

def setup_sentry():
    """Configure Sentry error tracking"""
    sentry_dsn = os.getenv('SENTRY_DSN')
    environment = os.getenv('ENVIRONMENT', 'development')
    
    if sentry_dsn:
        sentry_sdk.init(
            dsn=sentry_dsn,
            environment=environment,
            traces_sample_rate=1.0 if environment == 'development' else 0.1,
            profiles_sample_rate=1.0 if environment == 'development' else 0.1,
            integrations=[
                FastApiIntegration(),
                HttpxIntegration(),
            ],
            # Send PII (Personally Identifiable Information)
            send_default_pii=False,
            # Attach stack traces
            attach_stacktrace=True,
            # Max breadcrumbs
            max_breadcrumbs=50,
        )
        print(f"✅ Sentry initialized for {environment}")
    else:
        print("⚠️  Sentry DSN not configured - error tracking disabled")

# Initialize
logger = setup_logging()
setup_sentry()

# Helper functions for structured logging
def log_info(message: str, **kwargs):
    """Log info with structured data"""
    logger.info(message, extra=kwargs)

def log_error(message: str, error: Exception = None, **kwargs):
    """Log error with structured data and send to Sentry"""
    if error:
        kwargs['error_type'] = type(error).__name__
        kwargs['error_message'] = str(error)
        sentry_sdk.capture_exception(error)
    
    logger.error(message, extra=kwargs)

def log_warning(message: str, **kwargs):
    """Log warning with structured data"""
    logger.warning(message, extra=kwargs)

def log_debug(message: str, **kwargs):
    """Log debug with structured data"""
    logger.debug(message, extra=kwargs)

# Context managers for tracking operations
class LogContext:
    """Context manager for logging operations"""
    def __init__(self, operation: str, **kwargs):
        self.operation = operation
        self.context = kwargs
    
    def __enter__(self):
        log_info(f"{self.operation} started", **self.context)
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            log_error(
                f"{self.operation} failed",
                error=exc_val,
                **self.context
            )
        else:
            log_info(f"{self.operation} completed", **self.context)
