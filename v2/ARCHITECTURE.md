# Captive Portal Native Ad System - Architecture

## Overview

This document describes the architecture for serving native ads in a captive portal environment, designed for real-world conditions including slow networks, limited browser capabilities, and aggressive timeouts.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER JOURNEY                                    │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌──────────┐         ┌──────────┐         ┌──────────┐         ┌──────────┐
    │  Connect │   ───▶  │  Pre-Auth│   ───▶  │Post-Auth │   ───▶  │   Free   │
    │  to WiFi │         │  + Ads   │         │ + Ads    │         │ Browsing │
    └──────────┘         └──────────┘         └──────────┘         └──────────┘
                              │                    │
                              ▼                    ▼
                         ┌─────────────────────────────┐
                         │      Ad Impression          │
                         │      + Click Tracking       │
                         └─────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                           SYSTEM COMPONENTS                                  │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   MikroTik   │     │   Ad Proxy   │     │   Ads API    │     │   Beacon     │
│   Hotspot    │     │   Server     │     │  (3rd Party) │     │   Server     │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │                    │
       │  Serves HTML       │  Fetches ads       │  Returns JSON      │  Tracks
       │  (login.html,      │  Handles CORS      │  Native ad data    │  impressions
       │   alogin.html)     │  Caches responses  │                    │  & clicks
       │                    │  Adds tracking     │                    │
       └────────────────────┴────────────────────┴────────────────────┘
```

---

## Ad Flow Sequence

```
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│ Browser │  │MikroTik │  │Ad Proxy │  │ Ads API │  │ Beacon  │
└────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘
     │            │            │            │            │
     │ 1. GET /   │            │            │            │
     │───────────▶│            │            │            │
     │            │            │            │            │
     │ 2. Return  │            │            │            │
     │   HTML     │            │            │            │
     │◀───────────│            │            │            │
     │            │            │            │            │
     │ 3. Fetch ads via XHR    │            │            │
     │────────────────────────▶│            │            │
     │            │            │            │            │
     │            │            │ 4. Fetch   │            │
     │            │            │───────────▶│            │
     │            │            │            │            │
     │            │            │ 5. JSON    │            │
     │            │            │◀───────────│            │
     │            │            │            │            │
     │ 6. Return ad JSON       │            │            │
     │◀────────────────────────│            │            │
     │            │            │            │            │
     │ 7. Render ad            │            │            │
     │────────┐   │            │            │            │
     │        │   │            │            │            │
     │◀───────┘   │            │            │            │
     │            │            │            │            │
     │ 8. Fire impression beacon            │            │
     │──────────────────────────────────────────────────▶│
     │            │            │            │            │
     │ 9. User clicks ad       │            │            │
     │────────────────────────▶│ (via clickUrl)          │
     │            │            │───────────────────────▶ │ (tracks click)
     │            │            │            │            │
```

---

## API Response Format

The Ad Proxy should return JSON in this format:

```json
{
  "ads": [
    {
      "id": "ad_12345",
      "title": "Premium Coffee Experience",
      "description": "Get 20% off your first order",
      "imageUrl": "https://cdn.example.com/ads/coffee.jpg",
      "clickUrl": "https://track.example.com/click?ad=12345&redirect=https://shop.example.com",
      "impressionUrl": "https://track.example.com/impression?ad=12345",
      "ctaText": "Shop Now"
    },
    {
      "id": "ad_12346",
      "title": "Fashion Sale",
      "description": "Up to 50% off summer collection",
      "imageUrl": "https://cdn.example.com/ads/fashion.jpg",
      "clickUrl": "https://track.example.com/click?ad=12346&redirect=https://fashion.example.com",
      "impressionUrl": "https://track.example.com/impression?ad=12346",
      "ctaText": "Browse"
    }
  ],
  "ttl": 300,
  "fallback": {
    "title": "Poptar WiFi",
    "description": "Fast & Secure Internet"
  }
}
```

---

## Backend Proxy (Node.js Example)

```javascript
// ad-proxy-server.js
const express = require('express');
const axios = require('axios');
const NodeCache = require('node-cache');

const app = express();
const cache = new NodeCache({ stdTTL: 300 }); // 5 min cache

// CORS headers for captive portal browsers
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  res.header('Cache-Control', 'public, max-age=60');
  next();
});

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok' }));

// Ad endpoint
app.get('/api/ads', async (req, res) => {
  try {
    // Check cache first
    const cached = cache.get('ads');
    if (cached) {
      return res.json(cached);
    }

    // Fetch from 3rd party API
    const response = await axios.get(process.env.ADS_API_URL, {
      headers: {
        'Authorization': `Bearer ${process.env.ADS_API_KEY}`,
        'X-Placement': 'captive-portal'
      },
      timeout: 2000
    });

    // Transform to our format
    const ads = transformAds(response.data);

    // Cache the response
    cache.set('ads', ads);

    res.json(ads);
  } catch (error) {
    console.error('Ad fetch error:', error.message);

    // Return fallback
    res.json({
      ads: [],
      fallback: {
        title: 'Poptar WiFi',
        description: 'Fast & Secure Internet'
      }
    });
  }
});

function transformAds(apiResponse) {
  // Transform 3rd party API response to our standard format
  // This varies based on the ad provider
  return {
    ads: apiResponse.native_ads?.map(ad => ({
      id: ad.id,
      title: ad.headline,
      description: ad.body,
      imageUrl: ad.image?.url,
      clickUrl: ad.click_url,  // Must include tracking!
      impressionUrl: ad.impression_tracker,
      ctaText: ad.cta_text || 'Learn More'
    })) || []
  };
}

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Ad proxy running on port ${PORT}`));
```

---

## Captive Portal Browser Quirks

### iOS (CaptiveNetworkSupport / CNA)

| Issue | Mitigation |
|-------|------------|
| Limited JS execution time (~10s) | Fast ad fetch with 3s timeout |
| No localStorage/cookies persistence | Don't rely on client storage |
| Auto-closes on "Success" text detection | Include hidden `Success` span |
| Limited viewport (sheet-style on newer iOS) | Mobile-first design, small assets |
| target="_blank" may not work | Link still works, opens in Safari after |

### Android (WebView / Chrome Custom Tabs)

| Issue | Mitigation |
|-------|------------|
| Various manufacturers modify behavior | Test on Samsung, Xiaomi, Pixel |
| Some block external image loading | Use walled garden for CDN domains |
| Connectivity check may bypass portal | Block `connectivitycheck.gstatic.com` |
| Notification-style portal on some devices | Keep page height reasonable |

### Windows (NetworkPresenter)

| Issue | Mitigation |
|-------|------------|
| Opens in Edge WebView | Standard HTML/CSS works well |
| May have popup blockers | Don't rely on window.open() |
| Larger viewport | Responsive design handles this |

### macOS (Captive Network Assistant)

| Issue | Mitigation |
|-------|------------|
| Similar to iOS CNA | Same mitigations apply |
| Better JS support | Can use slightly more complex logic |

---

## Performance Optimizations

### Critical Rendering Path

```
┌─────────────────────────────────────────────────────────────────┐
│                    LOADING SEQUENCE                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  0ms    HTML starts loading                                     │
│         ↓                                                       │
│  50ms   Inline CSS parsed (critical styles)                     │
│         ↓                                                       │
│  100ms  First paint (header, loading state)                     │
│         ↓                                                       │
│  150ms  JS starts executing                                     │
│         ↓                                                       │
│  200ms  Ad fetch initiated (XHR)                                │
│         ↓                                                       │
│  500ms  Ad images start loading (lazy)                          │
│         ↓                                                       │
│  800ms  First ad rendered                                       │
│         ↓                                                       │
│  1000ms Impressions fired                                       │
│                                                                 │
│  TARGET: < 1s perceived load time                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Optimization Checklist

- [x] **Inline critical CSS** - No external stylesheet blocking render
- [x] **No external JS libraries** - Vanilla JS only (~5KB total)
- [x] **Lazy load images** - `loading="lazy"` attribute
- [x] **Preconnect hints** - DNS prefetch for ad server
- [x] **Aggressive timeouts** - 3s for ads, 2s for beacons
- [x] **Fallback content** - Show house ad if API fails
- [x] **Image error handling** - Hide broken images gracefully
- [x] **Cache ad responses** - Backend caches for 5 minutes

---

## Walled Garden Configuration

Add these domains to MikroTik walled garden for ad system to work:

```bash
# Ad Proxy Server
/ip hotspot walled-garden add dst-host="your-ad-proxy.example.com" action=allow

# CDN for ad images (example domains)
/ip hotspot walled-garden add dst-host="*.cloudfront.net" action=allow
/ip hotspot walled-garden add dst-host="cdn.example.com" action=allow

# Beacon/tracking server
/ip hotspot walled-garden add dst-host="track.example.com" action=allow

# Google Fonts (if used)
/ip hotspot walled-garden add dst-host="fonts.googleapis.com" action=allow
/ip hotspot walled-garden add dst-host="fonts.gstatic.com" action=allow
```

---

## Impression & Click Tracking

### Impression Rules

1. Fire **once per ad per page load**
2. Fire when ad **becomes visible** (enters viewport)
3. Use **image beacon** for reliability (not fetch/XHR)
4. Track in state to prevent duplicates
5. Fire even if user doesn't interact

### Click Rules

1. Always use **provided clickUrl** (never bypass)
2. clickUrl contains tracking redirect
3. Open in **new tab** where supported
4. For captive browsers that don't support new tabs, direct navigation is acceptable

### Beacon Implementation

```javascript
// Most reliable method for captive portals
function fireBeacon(url) {
  var img = new Image();
  img.src = url + '?_t=' + Date.now();  // Cache buster
  // No need to wait for load - request is sent immediately
}
```

---

## Error Handling Matrix

| Scenario | Behavior | User Impact |
|----------|----------|-------------|
| Ad API timeout (>3s) | Show fallback ad | None - sees house ad |
| Ad API returns empty | Show fallback ad | None - sees house ad |
| Ad API returns error | Show fallback ad | None - sees house ad |
| Image fails to load | Hide image element | Sees text-only ad |
| Beacon fails to fire | Silent failure | None (tracking loss) |
| Click URL fails | Browser shows error | User can retry |
| JS disabled | Form still works | No ads, but can connect |

---

## Security Considerations

1. **XSS Prevention**: All ad content is escaped with `escapeHtml()`
2. **No eval()**: JSON parsed with try/catch, no dynamic code execution
3. **HTTPS Only**: All resources loaded over HTTPS
4. **No Fingerprinting**: No device fingerprinting or invasive tracking
5. **rel="noopener"**: External links include noopener for security

---

## File Structure

```
/flash/hotspot/           (MikroTik)
├── login.html           # Pre-auth page with ads
├── alogin.html          # Post-auth page with ads
├── logout.html          # Logout page (standard)
├── error.html           # Error page (standard)
└── redirect.html        # Redirect handler (standard)

/ad-proxy/               (External Server)
├── server.js            # Express server
├── cache.js             # Caching layer
├── transform.js         # API response transformer
└── config.js            # API keys, endpoints
```

---

## Monitoring & Analytics

Track these metrics:

| Metric | Description |
|--------|-------------|
| `ad_request_count` | Total ad API requests |
| `ad_request_latency` | Time to fetch ads (p50, p95, p99) |
| `ad_fallback_rate` | % of requests showing fallback |
| `impression_count` | Total impressions fired |
| `click_count` | Total ad clicks |
| `ctr` | Click-through rate (clicks/impressions) |
| `auth_success_rate` | % of users completing auth |

---

## Testing Checklist

- [ ] Test on iOS (iPhone, iPad) - CNA behavior
- [ ] Test on Android (Pixel, Samsung, Xiaomi)
- [ ] Test on Windows 10/11
- [ ] Test on macOS
- [ ] Test with slow network (3G simulation)
- [ ] Test with ad API timeout
- [ ] Test with ad API returning empty
- [ ] Test impression beacon firing
- [ ] Test click tracking
- [ ] Test fallback ad display
- [ ] Test carousel rotation
- [ ] Test back button blocking
