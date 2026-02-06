# Kill Switch Pro - Architecture Improvements & Recommendations

## 🎯 Current Implementation Status

### ✅ Just Added: Virtual Card Management
- **Lithic SDK Integration** for creating disposable virtual cards
- **Card Lifecycle Management**: Create → Pause → Close
- **Transaction Monitoring**: Track what charges were blocked
- **Enhanced BIN Lookup**: API key support for higher rate limits

---

## 🏗️ Backend Architecture Improvements

### 1. **Database Layer** (CRITICAL - Currently Missing)

**Current State**: Using in-memory dictionaries  
**Problem**: Data lost on server restart  
**Solution**: Implement proper database

#### Recommended: **Supabase** (PostgreSQL + Real-time)
```python
# Install
pip install supabase

# Schema Design
tables:
  - users (id, email, created_at, plaid_access_token_encrypted)
  - subscriptions (id, user_id, name, price, status, virtual_card_id, detected_at)
  - virtual_cards (id, user_id, lithic_card_id, subscription_id, status)
  - transactions (id, card_id, amount, merchant, status, created_at)
  - kill_history (id, user_id, subscription_id, killed_at, savings)
```

**Benefits**:
- Real-time sync between devices
- Built-in auth (can replace Firebase)
- Row-level security
- Automatic API generation

#### Alternative: **Firebase Firestore**
```python
# Collections
/users/{userId}/
  /subscriptions/{subId}
  /virtualCards/{cardId}
  /killHistory/{killId}
```

### 2. **Caching Layer** (HIGH PRIORITY)

**Current State**: Python dictionaries  
**Problem**: Not shared across instances, lost on restart  
**Solution**: Redis

```python
# Install
pip install redis

# Usage
import redis
redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)

# Cache BIN lookups (24 hour TTL)
redis_client.setex(f"bin:{bin_6}", 86400, json.dumps(card_data))

# Cache Plaid access tokens
redis_client.setex(f"plaid:{user_id}", 3600, access_token)
```

### 3. **Background Jobs** (MEDIUM PRIORITY)

**Use Case**: Periodic subscription scanning  
**Solution**: Celery + Redis

```python
# Install
pip install celery[redis]

# Tasks
@celery.task
def scan_user_gmail(user_id):
    # Scan for new subscriptions
    pass

@celery.task
def check_trial_expiration(user_id):
    # Alert users about expiring trials
    pass

# Schedule
from celery.schedules import crontab
app.conf.beat_schedule = {
    'scan-all-users': {
        'task': 'scan_user_gmail',
        'schedule': crontab(hour=2, minute=0),  # 2 AM daily
    },
}
```

### 4. **API Rate Limiting** (MEDIUM PRIORITY)

**Problem**: No protection against abuse  
**Solution**: slowapi

```python
# Install
pip install slowapi

from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.post("/api/v1/cards/create-virtual")
@limiter.limit("5/minute")  # Max 5 cards per minute
async def create_virtual_card(request: Request, ...):
    pass
```

### 5. **Webhook Handlers** (HIGH PRIORITY)

**Use Case**: Receive real-time updates from Lithic  
**Implementation**:

```python
@app.post("/webhooks/lithic")
async def lithic_webhook(request: Request):
    """
    Handle Lithic events:
    - card.created
    - card.state_changed
    - transaction.created
    - transaction.updated
    """
    payload = await request.json()
    signature = request.headers.get("lithic-signature")
    
    # Verify webhook signature
    if not verify_lithic_signature(payload, signature):
        raise HTTPException(status_code=401)
    
    event_type = payload.get("event_type")
    
    if event_type == "transaction.created":
        # Notify user of new charge
        await send_push_notification(...)
    
    return {"status": "received"}
```

### 6. **Error Handling & Logging** (HIGH PRIORITY)

```python
# Install
pip install sentry-sdk python-json-logger

import sentry_sdk
sentry_sdk.init(dsn="your-sentry-dsn")

# Structured logging
import logging
from pythonjsonlogger import jsonlogger

logger = logging.getLogger()
logHandler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter()
logHandler.setFormatter(formatter)
logger.addHandler(logHandler)

# Usage
logger.info("Card created", extra={
    "user_id": user_id,
    "card_id": card_id,
    "subscription": sub_name
})
```

### 7. **Security Enhancements** (CRITICAL)

```python
# 1. Encrypt sensitive data at rest
from cryptography.fernet import Fernet

ENCRYPTION_KEY = os.getenv('ENCRYPTION_KEY')
cipher = Fernet(ENCRYPTION_KEY)

def encrypt_token(token: str) -> str:
    return cipher.encrypt(token.encode()).decode()

def decrypt_token(encrypted: str) -> str:
    return cipher.decrypt(encrypted.encode()).decode()

# 2. Add API authentication
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()

@app.post("/api/v1/cards/create-virtual")
async def create_virtual_card(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    ...
):
    # Verify JWT token
    user_id = verify_jwt(credentials.credentials)
    ...

# 3. CORS configuration
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://killswitch.app"],  # Your production domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## 📱 Frontend Architecture Improvements

### 1. **State Management** (HIGH PRIORITY)

**Current State**: setState() everywhere  
**Problem**: Prop drilling, hard to maintain  
**Solution**: Riverpod or Bloc

#### Option A: Riverpod (Recommended)
```dart
// Install
flutter pub add flutter_riverpod

// Providers
final subscriptionsProvider = FutureProvider<List<Subscription>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final result = await apiService.scanGmail();
  return result.subscriptions;
});

final virtualCardsProvider = StateNotifierProvider<VirtualCardsNotifier, List<VirtualCard>>((ref) {
  return VirtualCardsNotifier();
});

// Usage in widgets
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionsProvider);
    
    return subscriptions.when(
      data: (subs) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(err),
    );
  }
}
```

#### Option B: Bloc Pattern
```dart
// Install
flutter pub add flutter_bloc

// Events
abstract class SubscriptionEvent {}
class LoadSubscriptions extends SubscriptionEvent {}
class KillSubscription extends SubscriptionEvent {
  final String id;
  KillSubscription(this.id);
}

// States
abstract class SubscriptionState {}
class SubscriptionsLoading extends SubscriptionState {}
class SubscriptionsLoaded extends SubscriptionState {
  final List<Subscription> subscriptions;
  SubscriptionsLoaded(this.subscriptions);
}

// Bloc
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final ApiService apiService;
  
  SubscriptionBloc(this.apiService) : super(SubscriptionsLoading()) {
    on<LoadSubscriptions>(_onLoad);
    on<KillSubscription>(_onKill);
  }
  
  Future<void> _onLoad(LoadSubscriptions event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionsLoading());
    final result = await apiService.scanGmail();
    emit(SubscriptionsLoaded(result.subscriptions));
  }
}
```

### 2. **Offline Support** (MEDIUM PRIORITY)

```dart
// Install
flutter pub add hive flutter_offline

// Local database
@HiveType(typeId: 0)
class SubscriptionCache extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  double price;
  
  @HiveField(3)
  DateTime lastSynced;
}

// Sync strategy
class OfflineFirstRepository {
  Future<List<Subscription>> getSubscriptions() async {
    // 1. Return cached data immediately
    final cached = await _loadFromCache();
    
    // 2. Fetch fresh data in background
    try {
      final fresh = await apiService.scanGmail();
      await _saveToCache(fresh);
      return fresh.subscriptions;
    } catch (e) {
      // 3. Return cached if network fails
      return cached;
    }
  }
}
```

### 3. **Push Notifications** (HIGH PRIORITY)

```dart
// Install
flutter pub add firebase_messaging

// Setup
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  Future<void> initialize() async {
    // Request permission
    await _fcm.requestPermission();
    
    // Get FCM token
    String? token = await _fcm.getToken();
    // Send to backend
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  
  void _showLocalNotification(RemoteMessage message) {
    // Show notification about:
    // - New subscription detected
    // - Trial about to expire
    // - Charge blocked by virtual card
  }
}
```

### 4. **Deep Linking** (MEDIUM PRIORITY)

```dart
// Install
flutter pub add go_router

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => MainNavigationScreen(),
    ),
    GoRoute(
      path: '/subscription/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SubscriptionDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: '/kill/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return KillConfirmationScreen(id: id);
      },
    ),
  ],
);

// Deep link: killswitch://kill/netflix-123
```

### 5. **Analytics & Crash Reporting** (HIGH PRIORITY)

```dart
// Install
flutter pub add firebase_analytics firebase_crashlytics

// Track events
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  void logSubscriptionKilled(String subscriptionId, double savings) {
    _analytics.logEvent(
      name: 'subscription_killed',
      parameters: {
        'subscription_id': subscriptionId,
        'savings': savings,
      },
    );
  }
  
  void logVirtualCardCreated(String subscriptionName) {
    _analytics.logEvent(
      name: 'virtual_card_created',
      parameters: {'subscription': subscriptionName},
    );
  }
}

// Crash reporting
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  runApp(MyApp());
}
```

### 6. **Testing** (CRITICAL)

```dart
// Install
flutter pub add mockito build_runner

// Unit tests
void main() {
  group('ApiService', () {
    late ApiService apiService;
    late MockHttpClient mockClient;
    
    setUp(() {
      mockClient = MockHttpClient();
      apiService = ApiService(client: mockClient);
    });
    
    test('scanGmail returns subscriptions', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => Response(mockSubscriptionJson, 200),
      );
      
      final result = await apiService.scanGmail();
      expect(result.subscriptions.length, 3);
    });
  });
}

// Widget tests
void main() {
  testWidgets('Kill button shows confirmation dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SubscriptionItem(subscription: mockSubscription),
      ),
    );
    
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    
    expect(find.text('Kill Subscription?'), findsOneWidget);
  });
}

// Integration tests
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('End-to-end kill flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Login
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    
    // Navigate to subscription
    await tester.tap(find.text('Netflix'));
    await tester.pumpAndSettle();
    
    // Kill subscription
    await tester.tap(find.text('Kill'));
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    
    expect(find.text('Subscription Killed'), findsOneWidget);
  });
}
```

---

## 🚀 Deployment & DevOps

### 1. **Backend Deployment**

#### Option A: Railway (Easiest)
```bash
# Install Railway CLI
npm install -g @railway/cli

# Deploy
railway login
railway init
railway up
```

#### Option B: Docker + Cloud Run
```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

```bash
# Deploy to Google Cloud Run
gcloud run deploy kill-switch-api \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

### 2. **Flutter App Distribution**

#### iOS
```bash
# Build
flutter build ipa --release

# Upload to TestFlight
xcrun altool --upload-app --type ios --file build/ios/ipa/*.ipa \
  --username "your@email.com" --password "app-specific-password"
```

#### Android
```bash
# Build
flutter build appbundle --release

# Upload to Google Play Console
# Use internal testing track first
```

### 3. **CI/CD Pipeline**

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to Railway
        run: |
          npm install -g @railway/cli
          railway up
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
  
  flutter:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter build ios --release
      - name: Upload to TestFlight
        uses: apple-actions/upload-testflight-build@v1
```

---

## 📊 Monitoring & Observability

### 1. **Application Monitoring**
- **Backend**: Sentry + Datadog
- **Frontend**: Firebase Crashlytics + Performance Monitoring

### 2. **Business Metrics Dashboard**
```python
# Track key metrics
metrics = {
    "total_subscriptions_killed": 1234,
    "total_savings_generated": 45678.90,
    "active_users": 567,
    "virtual_cards_created": 890,
    "avg_savings_per_user": 80.50,
}

# Send to analytics platform
mixpanel.track("daily_metrics", metrics)
```

---

## 🎯 Priority Implementation Order

### Phase 1 (Week 1-2): Foundation
1. ✅ Virtual card integration (DONE)
2. 🔴 Database setup (Supabase)
3. 🔴 User authentication (JWT)
4. 🔴 State management (Riverpod)

### Phase 2 (Week 3-4): Core Features
5. 🔴 Push notifications
6. 🔴 Offline support
7. 🔴 Error handling & logging
8. 🔴 Testing suite

### Phase 3 (Week 5-6): Scale & Polish
9. 🔴 Redis caching
10. 🔴 Background jobs
11. 🔴 Rate limiting
12. 🔴 CI/CD pipeline

### Phase 4 (Week 7-8): Production Ready
13. 🔴 Security audit
14. 🔴 Performance optimization
15. 🔴 Beta testing
16. 🔴 App store submission

---

## 💰 Cost Estimates (Monthly)

| Service | Free Tier | Paid (1000 users) |
|---------|-----------|-------------------|
| Supabase | 500MB DB | $25 |
| Railway (Backend) | $5 credit | $20 |
| Lithic (Virtual Cards) | Sandbox free | $0.10/card + interchange |
| Plaid | 100 items | $0.25/item |
| Firebase | 10K users | $25 |
| Sentry | 5K events | $26 |
| **Total** | **~$0** | **~$100-150** |

---

**Created**: January 30, 2026  
**Status**: Virtual card integration complete, architecture roadmap defined
