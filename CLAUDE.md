# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a MikroTik captive portal system with native ad integration for WiFi hotspots. The system is designed to work across all major platforms (iOS, Android 11-16, Windows, macOS) with aggressive performance optimizations for captive portal browser environments.

**Key Features:**
- Native ad integration via KahfAds API
- Mobile-first responsive design with Bengali language support
- RFC 8910 captive portal detection support
- Two-phase ad display (pre-auth and post-auth)
- Handles captive browser quirks (iOS CNA, Android WebView, etc.)

## Architecture

### High-Level Flow

```
User connects to WiFi → login.html (pre-auth with ads) → MikroTik auth → alogin.html (post-auth with two-phase ads) → Internet access
```

### Critical Components

1. **v2/login.html** - Pre-authentication page
   - Shows native ads before user connects
   - Self-contained HTML with inline CSS/JS (no external dependencies)
   - KahfAds API integration with fallback handling
   - MikroTik form submission using `$(link-login-only)` variable

2. **v2/alogin.html** - Post-authentication success page
   - Two-phase ad display: Phase 1 (card-based) → Phase 2 (full-page)
   - iOS captive portal trigger via hidden "Success" span
   - Countdown timers between phases
   - Same self-contained architecture as login.html

3. **mikrotik/** - MikroTik RouterOS configuration
   - captive-portal-setup.rsc: Complete automated setup script
   - working-config-v1.rsc: Reference configuration
   - Uses global variables for portability

### Key Technical Constraints

**Captive Portal Browser Limitations:**
- iOS CNA: ~10s JS execution limit, no localStorage, auto-closes on "Success" detection
- Android WebView: Varies by manufacturer, may block external images
- Limited fetch/XHR support across platforms
- Aggressive timeouts required (3-4s for ad fetch, 2s for beacons)

**Performance Requirements:**
- All CSS/JS must be inline (no external files)
- Vanilla JS only (no frameworks)
- Lazy-load images with fallback handling
- Target <1s perceived load time

## MikroTik Integration

### Important Variables (Used in HTML)

The HTML files use MikroTik server-side variables:
- `$(link-login-only)` - Form action for authentication
- `$(link-orig)` - Original destination URL
- These are replaced by MikroTik when serving the page

### Walled Garden Requirements

For ads to load, the ad server domain must be in MikroTik walled garden:
```
/ip hotspot walled-garden add dst-host="*.kahfads.com" action=allow
```

### Android 15/16 Compatibility

Critical requirements:
1. Enable MikroTik Cloud DNS (`/ip cloud set ddns-enabled=yes`)
2. Remove all DENY rules from walled garden (especially for connectivity checks)
3. Set DNS name in hotspot profile to Cloud DNS value

## Development Workflow

### Testing Changes

1. **Edit HTML files** in `v2/` directory
2. **Upload to MikroTik**:
   ```bash
   scp v2/login.html admin@ROUTER_IP:/flash/hotspot/login.html
   scp v2/alogin.html admin@ROUTER_IP:/flash/hotspot/alogin.html
   ```
3. **Test on multiple devices** (iOS, Android, Windows, macOS)
4. **Check captive portal detection** - Should auto-popup on connection

### Configuration Changes

**Ad Endpoint:**
Edit the `CONFIG` object in the `<script>` section of login.html and alogin.html:
```javascript
var CONFIG = {
    adEndpoint: 'https://ad.kahfads.com/ads-api-native?key=YOUR_KEY&native_bs=1',
    adTimeout: 4000,
    maxAds: 3,
    rotationInterval: 4000
};
```

**MikroTik Setup:**
Edit variables at the top of `mikrotik/captive-portal-setup.rsc`:
```
:global cpBridgeIP "192.168.50.1"
:global cpHotspotName "kahf-wifi"
:global cpWifiSSID "Kahf Free WiFi"
```
Then import: `/import captive-portal-setup.rsc`

## Code Structure Principles

### Self-Contained Pages
- Each HTML file is completely self-contained (inline CSS, inline JS)
- No external dependencies (jQuery, Bootstrap, etc.)
- All resources loaded via HTTPS
- XSS protection via `escapeHtml()` function for ad content

### Ad System Architecture
- **Fetch**: XHR request to ad endpoint with timeout
- **Render**: Display ads in carousel with rotation
- **Track**: Fire impression beacons when ads become visible
- **Fallback**: Show house ad if API fails/times out
- **Cache**: Backend proxy caches responses for 5 minutes

### State Management
All state is in-memory JavaScript objects:
```javascript
var state = {
    ads: [],              // Fetched ad data
    currentIndex: 0,      // Carousel position
    impressionsFired: {}, // Prevent duplicate tracking
    rotationTimer: null   // Carousel interval
};
```

## File Organization

```
v2/
├── login.html         # Pre-auth page (deployed to MikroTik)
├── alogin.html        # Post-auth page (deployed to MikroTik)
└── ARCHITECTURE.md    # Detailed technical documentation

mikrotik/
├── captive-portal-setup.rsc    # Automated setup script (import this)
├── working-config-v1.rsc       # Reference configuration
├── alogin.html                 # Legacy copy (use v2/ instead)
├── logout.html                 # Standard logout page
└── redirect.html               # Standard redirect handler
```

## Important Implementation Notes

1. **Never use external JS/CSS files** - Captive portals may not load them reliably
2. **Always include fallback ads** - Network conditions are unpredictable
3. **Test on real devices** - Emulators don't accurately simulate captive browser behavior
4. **iOS "Success" trigger** - Must be present but hidden for iOS CNA to auto-close
5. **Image error handling** - Hide broken images gracefully, don't break layout
6. **Beacon tracking** - Use `<img>` beacon pattern, not fetch() (more reliable)
7. **Bengali text encoding** - UTF-8 charset must be declared early in `<head>`

## Security Considerations

- All ad content is escaped via `escapeHtml()` to prevent XSS
- No `eval()` or dynamic code execution
- HTTPS-only for all resources
- `rel="noopener"` on external links
- No device fingerprinting or invasive tracking

## References

- Complete architecture documentation: `v2/ARCHITECTURE.md`
- MikroTik hotspot documentation: https://help.mikrotik.com/docs/display/ROS/Hotspot
- RFC 8910 (Captive Portal API): https://www.rfc-editor.org/rfc/rfc8910.html
