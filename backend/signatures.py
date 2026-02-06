SUBSCRIPTION_SIGNATURES = {
    # Video
    "Netflix": {
        "category": "Video",
        "cancel_url": "https://www.netflix.com/cancelplan",
        "keywords": ["netflix"],
    },
    "Disney+": {
        "category": "Video",
        "cancel_url": "https://www.disneyplus.com/account/subscription",
        "keywords": ["disney+"],
    },
    "Amazon Prime Video": {
        "category": "Video",
        "cancel_url": "https://www.amazon.com/gp/video/settings",
        "keywords": ["amazon prime video", "prime video"],
    },
    "Hulu": {
        "category": "Video",
        "cancel_url": "https://secure.hulu.com/account",
        "keywords": ["hulu"],
    },
    "HBO Max": {
        "category": "Video",
        "cancel_url": "https://play.hbomax.com/account/billing",
        "keywords": ["hbo max", "max"],
    },
    "Showmax": {
        "category": "Video",
        "cancel_url": "https://www.showmax.com/account/subscription",
        "keywords": ["showmax"],
    },
    "Apple TV+": {
        "category": "Video",
        "cancel_url": "https://support.apple.com/en-us/HT202039",
        "keywords": ["apple tv"],
    },
    "Paramount+": {
        "category": "Video",
        "cancel_url": "https://www.paramountplus.com/account/",
        "keywords": ["paramount+"],
    },

    # Music
    "Spotify": {
        "category": "Music",
        "cancel_url": "https://www.spotify.com/account/subscription/",
        "keywords": ["spotify"],
    },
    "Apple Music": {
        "category": "Music",
        "cancel_url": "https://support.apple.com/en-us/HT202039",
        "keywords": ["apple music"],
    },
    "YouTube Premium": {
        "category": "Music",
        "cancel_url": "https://www.youtube.com/paid_memberships",
        "keywords": ["youtube premium"],
    },
    "Tidal": {
        "category": "Music",
        "cancel_url": "https://account.tidal.com/subscription",
        "keywords": ["tidal"],
    },
    "Deezer": {
        "category": "Music",
        "cancel_url": "https://www.deezer.com/account/subscription",
        "keywords": ["deezer"],
    },
    "Audiomack (Premium)": {
        "category": "Music",
        "cancel_url": "https://audiomack.com/settings",
        "keywords": ["audiomack"],
    },

    # Work/AI
    "ChatGPT Plus": {
        "category": "Work/AI",
        "cancel_url": "https://chat.openai.com/#settings/billing",
        "keywords": ["chatgpt", "openai"],
    },
    "Adobe Creative Cloud": {
        "category": "Work/AI",
        "cancel_url": "https://account.adobe.com/plans",
        "keywords": ["adobe", "creative cloud", "lightroom", "photoshop"],
    },
    "Microsoft 365": {
        "category": "Work/AI",
        "cancel_url": "https://account.microsoft.com/services",
        "keywords": ["microsoft 365", "office 365"],
    },
    "Canva": {
        "category": "Work/AI",
        "cancel_url": "https://www.canva.com/settings/billing-and-plans",
        "keywords": ["canva"],
    },
    "LinkedIn Premium": {
        "category": "Work/AI",
        "cancel_url": "https://www.linkedin.com/premium/manage/",
        "keywords": ["linkedin premium"],
    },
    "GitHub Copilot": {
        "category": "Work/AI",
        "cancel_url": "https://github.com/settings/copilot",
        "keywords": ["github copilot"],
    },
    "Zoom": {
        "category": "Work/AI",
        "cancel_url": "https://zoom.us/billing/plan",
        "keywords": ["zoom"],
    },
    "Slack": {
        "category": "Work/AI",
        "cancel_url": "https://slack.com/help/articles/204212133-Cancel-your-Slack-subscription",
        "keywords": ["slack"],
    },

    # Lifestyle/Health
    "Calm": {
        "category": "Lifestyle/Health",
        "cancel_url": "https://www.calm.com/settings/subscription",
        "keywords": ["calm"],
    },
    "Headspace": {
        "category": "Lifestyle/Health",
        "cancel_url": "https://www.headspace.com/settings/subscription",
        "keywords": ["headspace"],
    },
    "Peloton": {
        "category": "Lifestyle/Health",
        "cancel_url": "https://www.onepeloton.com/settings/subscriptions",
        "keywords": ["peloton"],
    },
    "Strava": {
        "category": "Lifestyle/Health",
        "cancel_url": "https://www.strava.com/settings/subscription",
        "keywords": ["strava"],
    },
    "Duolingo": {
        "category": "Lifestyle/Health",
        "cancel_url": "https://www.duolingo.com/settings/plus",
        "keywords": ["duolingo"],
    },
    "Gym Pass": {
        "category": "Lifestyle/Health",
        "cancel_url": "https://gympass.com/us/settings/subscription",
        "keywords": ["gympass"],
    },

    # Storage/Utilities
    "Google One": {
        "category": "Storage/Utilities",
        "cancel_url": "https://one.google.com/settings",
        "keywords": ["google one"],
    },
    "iCloud": {
        "category": "Storage/Utilities",
        "cancel_url": "https://support.apple.com/en-us/HT202039",
        "keywords": ["icloud"],
    },
    "Dropbox": {
        "category": "Storage/Utilities",
        "cancel_url": "https://www.dropbox.com/account/plan",
        "keywords": ["dropbox"],
    },
    "Shopify": {
        "category": "Storage/Utilities",
        "cancel_url": "https://www.shopify.com/admin/settings/billing",
        "keywords": ["shopify"],
    },
    "Squarespace": {
        "category": "Storage/Utilities",
        "cancel_url": "https://www.squarespace.com/config/billing/subscriptions",
        "keywords": ["squarespace"],
    },
}

EXCHANGE_RATES = {
    "USD": 1.0,
    "GBP": 0.79,
    "NGN": 1500.0,
}

def normalize_currency(amount, from_currency, to_currency="USD"):
    if from_currency == to_currency:
        return amount
    
    # Convert to USD first
    if from_currency in EXCHANGE_RATES:
        usd_amount = amount / EXCHANGE_RATES[from_currency]
    else:
        usd_amount = amount
        
    # Convert from USD to target
    if to_currency in EXCHANGE_RATES:
        return usd_amount * EXCHANGE_RATES[to_currency]
    return usd_amount
