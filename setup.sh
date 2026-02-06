#!/bin/bash

# Kill Switch Pro - Setup Script
# This script helps you configure all the services

echo "🚀 Kill Switch Pro - Setup Assistant"
echo "===================================="
echo ""

# Check if .env exists
if [ ! -f "backend/.env" ]; then
    echo "❌ backend/.env not found!"
    exit 1
fi

echo "📋 Current Configuration Status:"
echo ""

# Function to check if env var is set
check_env() {
    local var_name=$1
    local var_value=$(grep "^$var_name=" backend/.env | cut -d '=' -f2)
    
    if [ -z "$var_value" ] || [ "$var_value" = "your_${var_name,,}_here" ] || [[ "$var_value" == *"your_"* ]]; then
        echo "❌ $var_name - Not configured"
        return 1
    else
        echo "✅ $var_name - Configured"
        return 0
    fi
}

# Check all services
check_env "LITHIC_API_KEY"
check_env "SUPABASE_URL"
check_env "SUPABASE_KEY"
check_env "REDIS_URL"
check_env "SENTRY_DSN"
check_env "PLAID_SECRET"

echo ""
echo "📦 Checking Dependencies:"
echo ""

# Check Redis
if command -v redis-cli &> /dev/null; then
    if redis-cli ping &> /dev/null; then
        echo "✅ Redis - Running"
    else
        echo "⚠️  Redis - Installed but not running"
        echo "   Run: brew services start redis"
    fi
else
    echo "❌ Redis - Not installed"
    echo "   Run: brew install redis"
fi

# Check Python packages
echo ""
echo "🐍 Checking Python Packages:"
python3 -c "import supabase" 2>/dev/null && echo "✅ supabase" || echo "❌ supabase"
python3 -c "import redis" 2>/dev/null && echo "✅ redis" || echo "❌ redis"
python3 -c "import sentry_sdk" 2>/dev/null && echo "✅ sentry-sdk" || echo "❌ sentry-sdk"
python3 -c "import celery" 2>/dev/null && echo "✅ celery" || echo "❌ celery"
python3 -c "import lithic" 2>/dev/null && echo "✅ lithic" || echo "✅ lithic"

echo ""
echo "📱 Next Steps:"
echo ""
echo "1. Configure Supabase:"
echo "   - Sign up at https://supabase.com"
echo "   - Create a new project"
echo "   - Copy URL and anon key to .env"
echo "   - Run the SQL schema from IMPLEMENTATION_COMPLETE.md"
echo ""
echo "2. Configure Sentry (optional):"
echo "   - Sign up at https://sentry.io"
echo "   - Create a Python project"
echo "   - Copy DSN to .env"
echo ""
echo "3. Start Redis (if not running):"
echo "   brew services start redis"
echo ""
echo "4. Install missing Python packages:"
echo "   cd backend && pip install -r requirements.txt"
echo ""
echo "5. Start the backend:"
echo "   cd backend && python3 main.py"
echo ""
echo "6. (Optional) Start Celery worker:"
echo "   cd backend && celery -A tasks worker --beat --loglevel=info"
echo ""
