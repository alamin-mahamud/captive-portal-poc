# MikroTik Captive Portal Setup Guide

> A step-by-step guide to set up a WiFi captive portal (like the login pages you see at cafes, airports, or hotels) using MikroTik routers.

---

## What is a Captive Portal?

Imagine you're at Starbucks and connect to their WiFi. Before you can browse Instagram, a login page pops up asking you to accept terms or watch an ad. That's a **captive portal**!

```
   Your Phone                    MikroTik Router                  Internet
       📱  -----(WiFi)---->  [🔒 Captive Portal] ------>  🌐
                                     |
                              "Watch this ad first,
                               then you can browse!"
```

---

## How It Works (The Simple Version)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CAPTIVE PORTAL FLOW                              │
└─────────────────────────────────────────────────────────────────────────┘

  Step 1: Connect to WiFi
  ┌──────┐                      ┌──────────────┐
  │ 📱   │ ───── WiFi ─────────>│   MikroTik   │
  │Phone │                      │    Router    │
  └──────┘                      └──────────────┘
     │                                 │
     │  "I want to go to google.com"   │
     │ ──────────────────────────────> │
     │                                 │
     │                          ┌──────┴──────┐
     │                          │  BLOCKED!   │
     │                          │ Not logged  │
     │                          │   in yet    │
     │                          └──────┬──────┘
     │                                 │
     │  "Here's a login page instead"  │
     │ <────────────────────────────── │
     │                                 │
     ▼                                 ▼

  Step 2: Show Login Page (Splash Page)
  ┌──────────────────────────────────────┐
  │  ┌────────────────────────────────┐  │
  │  │    🛡️ Welcome to Kahf WiFi    │  │
  │  │                                │  │
  │  │   [  Watch 15s Ad  ]          │  │
  │  │                                │  │
  │  │   [ Connect to WiFi ]         │  │
  │  └────────────────────────────────┘  │
  │              Your Phone              │
  └──────────────────────────────────────┘
     │
     │  User clicks "Connect"
     ▼

  Step 3: Access Granted!
  ┌──────┐                      ┌──────────────┐                    ┌────────┐
  │ 📱   │ ───── WiFi ─────────>│   MikroTik   │ ───── Internet ───>│   🌐   │
  │Phone │                      │  ✅ Allowed  │                    │ Google │
  └──────┘                      └──────────────┘                    └────────┘
```

---

## Key Terms (Explained Simply)

| Term | What It Means | Real-Life Example |
|------|---------------|-------------------|
| **Hotspot** | A WiFi network that requires login before browsing | The WiFi at McDonald's |
| **Splash Page** | The login/welcome page shown to users | "Accept Terms & Conditions" page |
| **Walled Garden** | Websites allowed BEFORE login | The login page itself needs to load! |
| **DHCP** | Automatically gives your phone an IP address | Like getting a visitor badge at a building |
| **DNS** | Translates "google.com" to an IP address | Like a phone book for the internet |
| **Session Timeout** | How long before you need to login again | "Your session expires in 1 hour" |
| **MAC Address** | Your device's unique ID | Like a fingerprint for your phone |
| **Bridge** | Connects multiple ports together | Like connecting rooms with a hallway |

---

## Network Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           NETWORK DIAGRAM                                    │
└─────────────────────────────────────────────────────────────────────────────┘

                              INTERNET
                                 │
                                 │ (Your ISP connection)
                                 ▼
                    ┌────────────────────────┐
                    │      MikroTik Router   │
                    │  ┌──────────────────┐  │
                    │  │   ether1 (WAN)   │──┼──── To Internet/Modem
                    │  └──────────────────┘  │
                    │                        │
                    │  ┌──────────────────┐  │
                    │  │  bridge-hotspot  │  │     Virtual bridge that
                    │  │   192.168.50.1   │  │     groups ports together
                    │  └────────┬─────────┘  │
                    │           │            │
                    │     ┌─────┴─────┐      │
                    │     │           │      │
                    │  ┌──┴───┐   ┌───┴──┐   │
                    │  │ether2│   │ wlan1│   │
                    │  │(LAN) │   │(WiFi)│   │
                    │  └──┬───┘   └───┬──┘   │
                    └─────┼───────────┼──────┘
                          │           │
                          ▼           ▼
                    ┌─────────┐  ┌─────────┐
                    │   💻    │  │   📱    │
                    │   PC    │  │  Phone  │
                    │(wired)  │  │ (WiFi)  │
                    └─────────┘  └─────────┘

                    Both get IPs from: 192.168.50.0/24
                    Both see captive portal before browsing
```

---

## Prerequisites

Before you start, you need:

1. **MikroTik Router** with RouterOS (Level 4 license or higher)
   - Recommended: hAP ac lite (RB952Ui-5ac2nD) for WiFi
2. **External Splash Page** hosted somewhere (we use GitHub Pages)
3. **Access to MikroTik** via WinBox, WebFig, or SSH

---

## Configuration Steps

### Step 1: Create a Bridge for Hotspot

A bridge groups multiple ports together so they act as one network.

```
Why do we need a bridge?
┌─────────────────────────────────────────────────────────────┐
│  WITHOUT Bridge:              WITH Bridge:                  │
│                                                             │
│  ether2 ─── Network A         ether2 ─┐                     │
│  ether3 ─── Network B         ether3 ─┼─── Same Network     │
│  wlan1  ─── Network C         wlan1  ─┘    (bridge-hotspot) │
│                                                             │
│  (3 separate networks)        (1 unified network)           │
└─────────────────────────────────────────────────────────────┘
```

### Step 2: Assign IP Address to Bridge

The bridge needs an IP address so it can be the "gateway" for connected devices.

```
┌─────────────────────────────────────────┐
│         bridge-hotspot                  │
│         IP: 192.168.50.1/24             │
│                │                        │
│    ┌───────────┼───────────┐            │
│    │           │           │            │
│  Phone      Laptop      Tablet          │
│ .50.100    .50.101     .50.102          │
│                                         │
│  All devices use 192.168.50.1 as their  │
│  gateway (door to the internet)         │
└─────────────────────────────────────────┘
```

### Step 3: Create DHCP Server

DHCP automatically gives IP addresses to devices when they connect.

```
Without DHCP:                    With DHCP:
┌──────────────────────┐        ┌──────────────────────┐
│  "What's my IP?"     │        │  Router: "Here's     │
│  User: "Uh... I      │        │  your IP: 192.168.   │
│  don't know how      │   vs   │  50.100, gateway,    │
│  to set this up"     │        │  and DNS. You're     │
│  ❌ Can't connect    │        │  good to go!"        │
└──────────────────────┘        │  ✅ Auto-connected   │
                                └──────────────────────┘
```

### Step 4: Create Hotspot Server

The hotspot server intercepts traffic and shows the login page.

```
┌─────────────────────────────────────────────────────────────┐
│                    HOTSPOT SERVER                           │
│                                                             │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐   │
│  │   BEFORE    │     │   HOTSPOT   │     │    AFTER    │   │
│  │   LOGIN     │ ──> │   SERVER    │ ──> │   LOGIN     │   │
│  │             │     │             │     │             │   │
│  │ All traffic │     │ Checks if   │     │ Traffic     │   │
│  │ intercepted │     │ user logged │     │ flows       │   │
│  │             │     │ in          │     │ freely      │   │
│  └─────────────┘     └─────────────┘     └─────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Step 5: Configure Walled Garden

Walled garden = websites users can visit BEFORE logging in.

```
┌─────────────────────────────────────────────────────────────┐
│                     WALLED GARDEN                           │
│                                                             │
│  User NOT logged in yet, but needs to access:               │
│                                                             │
│  ✅ github.io        (where our splash page lives)          │
│  ✅ fonts.google.com (to load pretty fonts)                 │
│  ✅ youtube.com      (to show the ad video)                 │
│  ✅ kahfguard.com    (to load our logo)                     │
│                                                             │
│  ❌ instagram.com    (blocked until login)                  │
│  ❌ facebook.com     (blocked until login)                  │
│  ❌ everything else  (blocked until login)                  │
└─────────────────────────────────────────────────────────────┘
```

### Step 6: Set Session Timeout

How long before the user needs to login again.

```
Timeline:
─────────────────────────────────────────────────────────────>
│                                                            │
│  User        5 minutes        Session         Must login   │
│  logs in     of browsing      expires         again        │
│    │              │              │               │         │
│    ▼              ▼              ▼               ▼         │
│   ✅────────────────────────────❌──────────────🔒        │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## Portable Configuration Script

Copy and paste this into MikroTik terminal. **Edit the variables at the top first!**

```routeros
#───────────────────────────────────────────────────────────────────────────────
# MIKROTIK CAPTIVE PORTAL - PORTABLE CONFIGURATION
#
# Instructions:
# 1. Edit the CONFIGURATION VARIABLES below
# 2. Copy entire script
# 3. Paste into MikroTik Terminal (System > Terminal)
#───────────────────────────────────────────────────────────────────────────────

#═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION VARIABLES - EDIT THESE!
#═══════════════════════════════════════════════════════════════════════════════

:local bridgeName "bridge-hotspot"
:local bridgeIP "192.168.50.1"
:local networkPrefix "192.168.50"
:local dhcpPoolStart "192.168.50.100"
:local dhcpPoolEnd "192.168.50.254"
:local hotspotName "kahf-wifi"
:local wifiSSID "Kahf Free WiFi"
:local wifiPassword ""
:local splashPageURL "https://alamin-mahamud.github.io/captive-portal-poc/"
:local sessionTimeout "00:05:00"
:local dhcpLeaseTime "00:05:00"
:local hotspotInterface "wlan1"
:local lanPorts "ether2,ether3,ether4"

#═══════════════════════════════════════════════════════════════════════════════
# STEP 1: CREATE BRIDGE
#═══════════════════════════════════════════════════════════════════════════════

/interface bridge
add name=$bridgeName comment="Captive Portal Bridge"

# Add ports to bridge (edit lanPorts above to match your setup)
:foreach port in=[:toarray $lanPorts] do={
    /interface bridge port
    add bridge=$bridgeName interface=$port comment="Hotspot LAN Port"
}

# Add wireless interface to bridge (if exists)
:if ([:len [/interface wireless find name=$hotspotInterface]] > 0) do={
    /interface bridge port
    add bridge=$bridgeName interface=$hotspotInterface comment="Hotspot WiFi"
}

:log info "Step 1 Complete: Bridge created"

#═══════════════════════════════════════════════════════════════════════════════
# STEP 2: ASSIGN IP ADDRESS TO BRIDGE
#═══════════════════════════════════════════════════════════════════════════════

/ip address
add address="$bridgeIP/24" interface=$bridgeName comment="Hotspot Gateway"

:log info "Step 2 Complete: IP assigned to bridge"

#═══════════════════════════════════════════════════════════════════════════════
# STEP 3: CREATE DHCP SERVER
#═══════════════════════════════════════════════════════════════════════════════

# Create IP Pool
/ip pool
add name="pool-hotspot" ranges="$dhcpPoolStart-$dhcpPoolEnd"

# Create DHCP Server
/ip dhcp-server
add name="dhcp-hotspot" interface=$bridgeName address-pool="pool-hotspot" \
    lease-time=$dhcpLeaseTime disabled=no

# Create DHCP Network
/ip dhcp-server network
add address="$networkPrefix.0/24" gateway=$bridgeIP dns-server=$bridgeIP \
    comment="Hotspot Network"

:log info "Step 3 Complete: DHCP server created"

#═══════════════════════════════════════════════════════════════════════════════
# STEP 4: CONFIGURE WIRELESS (if applicable)
#═══════════════════════════════════════════════════════════════════════════════

:if ([:len [/interface wireless find name=$hotspotInterface]] > 0) do={
    /interface wireless
    set $hotspotInterface mode=ap-bridge ssid=$wifiSSID disabled=no

    :if ([:len $wifiPassword] > 0) do={
        /interface wireless security-profiles
        set default authentication-types=wpa2-psk mode=dynamic-keys \
            wpa2-pre-shared-key=$wifiPassword
    } else={
        /interface wireless security-profiles
        set default authentication-types="" mode=none
    }

    :log info "Step 4 Complete: Wireless configured"
} else={
    :log info "Step 4 Skipped: No wireless interface found"
}

#═══════════════════════════════════════════════════════════════════════════════
# STEP 5: CREATE HOTSPOT SERVER
#═══════════════════════════════════════════════════════════════════════════════

# Create Hotspot Server Profile
/ip hotspot profile
add name="hsprof-$hotspotName" \
    html-directory=hotspot \
    http-cookie-lifetime=1d \
    hotspot-address=$bridgeIP \
    login-by=http-chap,http-pap \
    use-radius=no \
    split-user-domain=no

# Create Hotspot Server
/ip hotspot
add name=$hotspotName \
    interface=$bridgeName \
    address-pool="pool-hotspot" \
    profile="hsprof-$hotspotName" \
    disabled=no

# Set session timeout
/ip hotspot user profile
set default session-timeout=$sessionTimeout idle-timeout=$sessionTimeout \
    shared-users=unlimited

:log info "Step 5 Complete: Hotspot server created"

#═══════════════════════════════════════════════════════════════════════════════
# STEP 6: CREATE GUEST USER
#═══════════════════════════════════════════════════════════════════════════════

/ip hotspot user
add name=guest password=guest server=$hotspotName profile=default \
    comment="Auto-login guest account"

:log info "Step 6 Complete: Guest user created"

#═══════════════════════════════════════════════════════════════════════════════
# STEP 7: CONFIGURE WALLED GARDEN (Pre-auth allowed sites)
#═══════════════════════════════════════════════════════════════════════════════

/ip hotspot walled-garden ip
# GitHub Pages (splash page host)
add dst-host="*.github.io" action=accept comment="GitHub Pages - Splash Page"
add dst-host="*.githubusercontent.com" action=accept comment="GitHub Assets"

# Google Fonts
add dst-host="*.googleapis.com" action=accept comment="Google Fonts API"
add dst-host="*.gstatic.com" action=accept comment="Google Static Assets"

# YouTube (for video ads)
add dst-host="*.youtube.com" action=accept comment="YouTube Videos"
add dst-host="*.ytimg.com" action=accept comment="YouTube Images"
add dst-host="*.googlevideo.com" action=accept comment="YouTube Video Stream"
add dst-host="*.ggpht.com" action=accept comment="Google Photos"

# Kahf Assets
add dst-host="*.kahfguard.com" action=accept comment="Kahf DNS Assets"
add dst-host="*.kahf.com.tr" action=accept comment="Kahf Main Site"

# Android Captive Portal Detection
add dst-host="connectivitycheck.gstatic.com" action=accept comment="Android Portal Check"
add dst-host="connectivitycheck.android.com" action=accept comment="Android Portal Check"
add dst-host="clients3.google.com" action=accept comment="Android Generate 204"

# iOS Captive Portal Detection - DENY to trigger CNA
/ip hotspot walled-garden
add dst-host="captive.apple.com" action=deny comment="iOS CNA Trigger"
add dst-host="*.apple.com" dst-port=80 action=deny comment="iOS CNA Trigger"
add dst-host="*.akamaiedge.net" action=deny comment="iOS CNA Trigger"

:log info "Step 7 Complete: Walled garden configured"

#═══════════════════════════════════════════════════════════════════════════════
# STEP 8: CONFIGURE EXTERNAL SPLASH PAGE REDIRECT
#═══════════════════════════════════════════════════════════════════════════════

# Set login page to redirect to external splash page
/ip hotspot profile
set "hsprof-$hotspotName" \
    login-url="$splashPageURL?link-login=http://$bridgeIP/login&link-orig=\$(link-orig)"

:log info "Step 8 Complete: External splash page configured"

#═══════════════════════════════════════════════════════════════════════════════
# STEP 9: ENABLE NAT (Internet Access)
#═══════════════════════════════════════════════════════════════════════════════

# Masquerade hotspot traffic (if not already configured)
/ip firewall nat
add chain=srcnat src-address="$networkPrefix.0/24" action=masquerade \
    comment="Hotspot NAT"

:log info "Step 9 Complete: NAT configured"

#═══════════════════════════════════════════════════════════════════════════════
# STEP 10: CONFIGURE SESSION LOGGING (Optional)
#═══════════════════════════════════════════════════════════════════════════════

/ip hotspot user profile
set default on-login="{ \
    :log info \"HOTSPOT LOGIN: \$user MAC=\$mac-address IP=\$address\"; \
}"

set default on-logout="{ \
    :log info \"HOTSPOT LOGOUT: \$user MAC=\$mac-address session=\$session-time\"; \
    :delay 1s; \
    /ip hotspot host remove [find mac-address=\$mac-address]; \
}"

:log info "Step 10 Complete: Session logging configured"

#═══════════════════════════════════════════════════════════════════════════════
# DONE!
#═══════════════════════════════════════════════════════════════════════════════

:log info "=========================================="
:log info "CAPTIVE PORTAL SETUP COMPLETE!"
:log info "=========================================="
:log info "Bridge: $bridgeName"
:log info "Gateway: $bridgeIP"
:log info "SSID: $wifiSSID"
:log info "Splash Page: $splashPageURL"
:log info "Session Timeout: $sessionTimeout"
:log info "=========================================="
```

---

## Quick Reference Commands

### View Connected Users
```routeros
/ip hotspot host print
```

### View Active Sessions
```routeros
/ip hotspot active print
```

### Kick a User
```routeros
/ip hotspot active remove [find user="guest"]
```

### View Session Logs
```routeros
/log print where topics~"hotspot"
```

### Temporarily Disable Hotspot
```routeros
/ip hotspot disable kahf-wifi
```

### Re-enable Hotspot
```routeros
/ip hotspot enable kahf-wifi
```

---

## Troubleshooting

### Portal Not Showing on Android

```
Problem: Android connects but no portal appears
┌─────────────────────────────────────────────────────────────┐
│  Android Phone                    MikroTik                  │
│       📱  ────── "Am I online?" ──────>  🔒                 │
│           (checks connectivitycheck.gstatic.com)            │
│                                                             │
│  If this check passes → Android thinks it's online          │
│  If this check fails  → Android shows portal                │
└─────────────────────────────────────────────────────────────┘

Solution: Make sure Android check domains are in walled-garden
but return proper "not connected" response.
```

### Portal Not Showing on iOS

```
Problem: iOS connects but no portal appears
┌─────────────────────────────────────────────────────────────┐
│  iOS needs captive.apple.com to be BLOCKED before login     │
│  This triggers the Captive Network Assistant (CNA)          │
│                                                             │
│  After login, page must contain "Success" keyword           │
│  for CNA to auto-close                                      │
└─────────────────────────────────────────────────────────────┘

Solution: Add deny rules for Apple domains in walled-garden.
```

### Session Timeout Not Working

```
Problem: User doesn't see portal again after timeout
┌─────────────────────────────────────────────────────────────┐
│  Session expires, but device remembers the connection       │
│                                                             │
│  Timeline:                                                  │
│  ────────────────────────────────────────────────>          │
│  Login ──── 5 min ──── Timeout ──── Device cached ❌        │
│                                                             │
│  Need to: Remove host entry on logout                       │
└─────────────────────────────────────────────────────────────┘

Solution: on-logout script removes host entry immediately.
```

---

## Files Structure

```
captive-portal-poc/
├── README.md              # This file
├── index.html             # Splash page (offline - before login)
├── connected.html         # Success page (online - after login)
└── mikrotik/
    ├── alogin.html        # MikroTik after-login page
    ├── logout.html        # MikroTik session expired page
    └── redirect.html      # MikroTik redirect helper
```

---

## Customization Guide

### Change Session Timeout
```routeros
# In the configuration variables:
:local sessionTimeout "01:00:00"    # 1 hour
:local dhcpLeaseTime "01:00:00"     # Match DHCP lease to session
```

### Add Password Protection
```routeros
# In the configuration variables:
:local wifiPassword "MySecurePassword123"
```

### Change Splash Page URL
```routeros
# In the configuration variables:
:local splashPageURL "https://your-domain.com/portal/"
```

---

## Security Considerations

1. **Guest credentials** are transmitted over HTTP (not HTTPS)
2. **MAC spoofing** can bypass session limits
3. **DHCP starvation** attacks possible without rate limiting
4. Consider adding **firewall rules** to limit bandwidth per user

---

## License

MIT License - Feel free to use and modify for your projects.
