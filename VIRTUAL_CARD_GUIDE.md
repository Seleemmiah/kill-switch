# Virtual Card Integration - Quick Start Guide

## 🎯 What Just Got Added

Your Kill Switch app now has **REAL virtual card management** powered by Lithic. Users can create disposable cards for each subscription and instantly kill them when needed.

---

## 🔑 Setup Instructions

### 1. Get Your Lithic API Key
Your API key is already in `.env`:
```
LITHIC_API_KEY=6e0a78c9-bec8-478e-a020-81f20fcdfa55
LITHIC_ENV=sandbox
```

**For Production:**
1. Sign up at [lithic.com](https://lithic.com)
2. Get your production API key
3. Update `LITHIC_ENV=production`

### 2. (Optional) Get BIN Lookup API Key
For higher rate limits on card verification:
1. Sign up at [binlist.net](https://binlist.net)
2. Add to `.env`: `BINLIST_API_KEY=your_key_here`

---

## 📱 How It Works (User Flow)

### Step 1: User Discovers Subscription
```
Dashboard → Scan Gmail → Finds "Netflix - $19.99/month"
```

### Step 2: Create Virtual Card
```dart
// User taps "Protect with Virtual Card"
final card = await apiService.createVirtualCard(
  subscriptionName: 'Netflix',
  merchantName: 'Netflix Inc.',
  spendingLimit: 19.99,
  userId: currentUser.id,
);

// Returns:
{
  "card_id": "card_abc123",
  "last_four": "4242",
  "cvv": "123",
  "exp_month": "12",
  "exp_year": "2027",
  "status": "OPEN",
  "spending_limit": 19.99
}
```

### Step 3: User Updates Payment Method
```
User goes to Netflix.com → Payment Settings → 
Enters virtual card details (card number, CVV, expiry)
```

### Step 4: Kill Subscription
```dart
// User taps "KILL" button
await apiService.pauseVirtualCard(card.cardId);
// or
await apiService.closeVirtualCard(card.cardId);

// Netflix tries to charge → DECLINED ❌
```

---

## 🔧 Backend API Endpoints

### Create Virtual Card
```bash
POST /api/v1/cards/create-virtual
Content-Type: application/json

{
  "subscription_name": "Netflix",
  "merchant_name": "Netflix Inc.",
  "spending_limit": 19.99,
  "user_id": "user_123"
}

Response:
{
  "card_id": "card_abc123",
  "last_four": "4242",
  "cvv": "123",
  "exp_month": "12",
  "exp_year": "2027",
  "status": "OPEN",
  "spending_limit": 19.99
}
```

### Pause Card (Soft Kill)
```bash
POST /api/v1/cards/pause/{card_id}

Response:
{
  "status": "success",
  "message": "Card 4242 paused successfully",
  "card_state": "PAUSED"
}
```

### Close Card (Hard Kill)
```bash
POST /api/v1/cards/close/{card_id}

Response:
{
  "status": "success",
  "message": "Card 4242 permanently closed",
  "card_state": "CLOSED"
}
```

### Get Transaction History
```bash
GET /api/v1/cards/{card_id}/transactions

Response:
{
  "card_id": "card_abc123",
  "transactions": [
    {
      "amount": 19.99,
      "merchant": "NETFLIX.COM",
      "status": "APPROVED",
      "created": "2026-01-15T10:30:00Z"
    },
    {
      "amount": 19.99,
      "merchant": "NETFLIX.COM",
      "status": "DECLINED",  // After pause
      "created": "2026-02-15T10:30:00Z"
    }
  ]
}
```

---

## 💡 Implementation Examples

### Example 1: Add "Create Virtual Card" Button to Subscription Item

```dart
// In subscription_item.dart or dashboard_screen.dart
ElevatedButton.icon(
  onPressed: () async {
    final apiService = ApiService();
    final card = await apiService.createVirtualCard(
      subscriptionName: subscription.name,
      merchantName: subscription.name,
      spendingLimit: subscription.price,
      userId: FirebaseAuth.instance.currentUser!.uid,
    );
    
    if (card != null) {
      // Show card details to user
      showDialog(
        context: context,
        builder: (_) => VirtualCardDialog(card: card),
      );
    }
  },
  icon: Icon(Icons.credit_card),
  label: Text('Create Virtual Card'),
)
```

### Example 2: Virtual Card Display Dialog

```dart
class VirtualCardDialog extends StatelessWidget {
  final Map<String, dynamic> card;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Virtual Card Created'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Card Number: •••• •••• •••• ${card['last_four']}'),
          Text('CVV: ${card['cvv']}'),
          Text('Expiry: ${card['exp_month']}/${card['exp_year']}'),
          SizedBox(height: 16),
          Text(
            'Use this card for ${card['subscription_name']}. '
            'You can pause or close it anytime.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Copy card details to clipboard
            Clipboard.setData(ClipboardData(
              text: 'Card: ${card['last_four']}\nCVV: ${card['cvv']}\nExp: ${card['exp_month']}/${card['exp_year']}'
            ));
            Navigator.pop(context);
          },
          child: Text('Copy Details'),
        ),
      ],
    );
  }
}
```

### Example 3: Enhanced Kill Button

```dart
// Update the kill_subscription method
Future<void> _killSubscription(Subscription sub) async {
  // If subscription has a virtual card, pause it
  if (sub.virtualCardId != null) {
    final success = await apiService.pauseVirtualCard(sub.virtualCardId!);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Virtual card paused - charges blocked!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  // Also call the regular kill endpoint
  await apiService.killSubscription(sub.id);
}
```

---

## 🎨 UI/UX Recommendations

### 1. **Subscription Card Badge**
Show if a subscription is protected by a virtual card:
```dart
if (subscription.hasVirtualCard)
  Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.green.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.shield, size: 12, color: Colors.green),
        SizedBox(width: 4),
        Text('Protected', style: TextStyle(fontSize: 10)),
      ],
    ),
  )
```

### 2. **Transaction History Screen**
```dart
class TransactionHistoryScreen extends StatelessWidget {
  final String cardId;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService().getCardTransactions(cardId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final tx = snapshot.data![index];
            return ListTile(
              leading: Icon(
                tx['status'] == 'APPROVED' 
                  ? Icons.check_circle 
                  : Icons.block,
                color: tx['status'] == 'APPROVED' 
                  ? Colors.green 
                  : Colors.red,
              ),
              title: Text(tx['merchant']),
              subtitle: Text(tx['created']),
              trailing: Text('\$${tx['amount']}'),
            );
          },
        );
      },
    );
  }
}
```

### 3. **Kill Confirmation with Card Status**
```dart
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: Text('Kill ${subscription.name}?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('This will:'),
        SizedBox(height: 8),
        if (subscription.hasVirtualCard) ...[
          Row(
            children: [
              Icon(Icons.credit_card_off, size: 16),
              SizedBox(width: 8),
              Text('Pause virtual card'),
            ],
          ),
          SizedBox(height: 4),
        ],
        Row(
          children: [
            Icon(Icons.block, size: 16),
            SizedBox(width: 8),
            Text('Block future charges'),
          ],
        ),
        SizedBox(height: 16),
        Text(
          'You\'ll save \$${subscription.price * 12}/year',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          _killSubscription(subscription);
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        child: Text('KILL'),
      ),
    ],
  ),
);
```

---

## 🔐 Security Best Practices

### 1. **Never Store Full Card Numbers**
```dart
// ❌ DON'T
final cardNumber = card['card_number'];  // Full PAN

// ✅ DO
final lastFour = card['last_four'];  // Only last 4 digits
```

### 2. **Encrypt Card IDs in Database**
```python
# Backend
from cryptography.fernet import Fernet

def store_card_mapping(user_id, subscription_id, card_id):
    encrypted_card_id = cipher.encrypt(card_id.encode())
    db.save({
        'user_id': user_id,
        'subscription_id': subscription_id,
        'card_id_encrypted': encrypted_card_id
    })
```

### 3. **Use Webhook Verification**
```python
# Verify Lithic webhooks
import hmac
import hashlib

def verify_webhook(payload, signature, secret):
    expected = hmac.new(
        secret.encode(),
        payload.encode(),
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature)
```

---

## 📊 Monitoring & Analytics

Track these metrics:
```dart
// Analytics events
analytics.logEvent(
  name: 'virtual_card_created',
  parameters: {
    'subscription': subscriptionName,
    'spending_limit': spendingLimit,
  },
);

analytics.logEvent(
  name: 'subscription_killed',
  parameters: {
    'method': 'virtual_card_pause',
    'savings': annualSavings,
  },
);
```

---

## 🚀 Next Steps

1. **Add UI for virtual card creation** in subscription detail screen
2. **Show card status** (OPEN, PAUSED, CLOSED) in dashboard
3. **Implement transaction history** viewer
4. **Add push notifications** when charges are blocked
5. **Create onboarding flow** explaining virtual cards

---

## 📞 Support

- **Lithic Docs**: https://docs.lithic.com
- **Sandbox Testing**: Use test card numbers from Lithic docs
- **Webhook Setup**: Configure at https://dashboard.lithic.com/webhooks

---

**Status**: ✅ Backend integration complete, ready for frontend implementation
