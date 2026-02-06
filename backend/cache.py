"""
Redis caching service for improved performance.
Caches BIN lookups, Plaid tokens, and frequently accessed data.
"""
import os
import json
import redis
from typing import Optional, Any
from dotenv import load_dotenv

load_dotenv()

class CacheService:
    def __init__(self):
        redis_url = os.getenv('REDIS_URL', 'redis://localhost:6379')
        
        try:
            self.client = redis.from_url(redis_url, decode_responses=True)
            self.client.ping()
            self.enabled = True
            print("✅ Redis connected")
        except Exception as e:
            self.client = None
            self.enabled = False
            print(f"⚠️  Redis not available - caching disabled: {e}")
    
    def get(self, key: str) -> Optional[Any]:
        """Get value from cache"""
        if not self.enabled:
            return None
        
        try:
            value = self.client.get(key)
            if value:
                return json.loads(value)
        except Exception as e:
            print(f"Cache get error: {e}")
        
        return None
    
    def set(self, key: str, value: Any, ttl: int = 3600) -> bool:
        """Set value in cache with TTL (default 1 hour)"""
        if not self.enabled:
            return False
        
        try:
            self.client.setex(key, ttl, json.dumps(value))
            return True
        except Exception as e:
            print(f"Cache set error: {e}")
            return False
    
    def delete(self, key: str) -> bool:
        """Delete key from cache"""
        if not self.enabled:
            return False
        
        try:
            self.client.delete(key)
            return True
        except Exception as e:
            print(f"Cache delete error: {e}")
            return False
    
    def clear_pattern(self, pattern: str) -> int:
        """Delete all keys matching pattern"""
        if not self.enabled:
            return 0
        
        try:
            keys = self.client.keys(pattern)
            if keys:
                return self.client.delete(*keys)
        except Exception as e:
            print(f"Cache clear error: {e}")
        
        return 0
    
    # --- SPECIALIZED CACHE METHODS ---
    
    def cache_bin_lookup(self, bin_6: str, data: dict, ttl: int = 86400) -> bool:
        """Cache BIN lookup result (24 hours)"""
        return self.set(f"bin:{bin_6}", data, ttl)
    
    def get_bin_lookup(self, bin_6: str) -> Optional[dict]:
        """Get cached BIN lookup"""
        return self.get(f"bin:{bin_6}")
    
    def cache_plaid_token(self, user_id: str, access_token: str, ttl: int = 3600) -> bool:
        """Cache Plaid access token (1 hour)"""
        return self.set(f"plaid:{user_id}", access_token, ttl)
    
    def get_plaid_token(self, user_id: str) -> Optional[str]:
        """Get cached Plaid token"""
        return self.get(f"plaid:{user_id}")
    
    def cache_user_subscriptions(self, user_id: str, subscriptions: list, ttl: int = 300) -> bool:
        """Cache user subscriptions (5 minutes)"""
        return self.set(f"subs:{user_id}", subscriptions, ttl)
    
    def get_user_subscriptions(self, user_id: str) -> Optional[list]:
        """Get cached subscriptions"""
        return self.get(f"subs:{user_id}")
    
    def invalidate_user_cache(self, user_id: str) -> int:
        """Clear all cache for a user"""
        return self.clear_pattern(f"*:{user_id}")

# Global instance
cache = CacheService()
