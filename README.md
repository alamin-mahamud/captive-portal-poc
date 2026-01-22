# Poptar WiFi - Captive Portal

MikroTik captive portal with native ad integration for WiFi hotspots.

## Features

- Native ad integration (KahfAds API)
- Mobile-first responsive design
- Bengali language support
- Works on iOS, Android 11-16, Windows, macOS
- RFC 8910 captive portal detection support

## Files

```
v2/
├── login.html      # Pre-auth page with ads
├── alogin.html     # Post-auth success page
└── ARCHITECTURE.md # System documentation
```

## Installation

### 1. Upload to MikroTik

```bash
scp v2/login.html admin@ROUTER_IP:/flash/hotspot/login.html
scp v2/alogin.html admin@ROUTER_IP:/flash/hotspot/alogin.html
```

### 2. Configure Hotspot Profile

```bash
# Enable Cloud DNS (for RFC 8910)
/ip cloud set ddns-enabled=yes

# Set DNS name in hotspot profile
/ip hotspot profile set [find] dns-name=[/ip cloud get dns-name]
```

### 3. Walled Garden Setup

```bash
# Allow ad server
/ip hotspot walled-garden add dst-host="*.kahfads.com" action=allow
/ip hotspot walled-garden add dst-host="cdn.kahfads.com" action=allow

# IMPORTANT: Remove any DENY rules for connectivity check
/ip hotspot walled-garden remove [find where action=deny]
```

## Android 15/16 Fix

For newer Android devices to show captive portal popup:

1. **Enable MikroTik Cloud DNS** - Provides valid DNS name
2. **Remove DENY rules** - Don't block `connectivitycheck.gstatic.com`
3. **Set DNS name in hotspot profile** - Required for RFC 8910

## Configuration

Edit `login.html` to customize:

```javascript
var CONFIG = {
    adEndpoint: 'https://ad.kahfads.com/ads-api-native?key=YOUR_KEY&native_bs=1',
    adTimeout: 4000,
    maxAds: 3,
    rotationInterval: 4000
};
```

## License

MIT
