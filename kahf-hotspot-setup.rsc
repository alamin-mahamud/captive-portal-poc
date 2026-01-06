# Kahf Free WiFi Captive Portal Setup Script
# ============================================
# This script configures a MikroTik router for captive portal with external splash page
# Compatible with RouterOS 6.x and 7.x
#
# CONFIGURATION - Edit these variables before running:
# ----------------------------------------------------

:local bridgeName "bridge-kahf-wifi"
:local poolName "pool-kahf-wifi"
:local poolRange "192.168.100.2-192.168.100.254"
:local gatewayIP "192.168.100.1"
:local networkCIDR "192.168.100.0/24"
:local hotspotInterface "ether4"
:local hotspotDNSName "wifi.kahf.local"
:local sessionTimeout "00:05:00"
:local splashPageURL "https://alamin-mahamud.github.io/captive-portal-poc/"

# ============================================
# SCRIPT START - Do not edit below this line
# ============================================

:log info "Kahf WiFi: Starting captive portal setup..."

# 1. Create Bridge
:log info "Kahf WiFi: Creating bridge..."
/interface bridge add name=$bridgeName comment="Kahf Free WiFi Bridge" protocol-mode=rstp

# 2. Create IP Pool
:log info "Kahf WiFi: Creating IP pool..."
/ip pool add name=$poolName ranges=$poolRange comment="Kahf Free WiFi Pool"

# 3. Assign IP to Bridge
:log info "Kahf WiFi: Assigning gateway IP..."
/ip address add address="$gatewayIP/24" interface=$bridgeName comment="Kahf Free WiFi Gateway"

# 4. Create DHCP Server
:log info "Kahf WiFi: Setting up DHCP..."
/ip dhcp-server network add address=$networkCIDR gateway=$gatewayIP dns-server=$gatewayIP comment="Kahf Free WiFi Network"
/ip dhcp-server add name="dhcp-kahf-wifi" interface=$bridgeName address-pool=$poolName lease-time=00:10:00 disabled=no comment="Kahf Free WiFi DHCP"

# 5. Setup Hotspot Server Profile
:log info "Kahf WiFi: Creating hotspot profile..."
/ip hotspot profile add name="kahf-wifi-profile" \
    hotspot-address=$gatewayIP \
    dns-name=$hotspotDNSName \
    html-directory=flash/hotspot \
    login-by=http-pap \
    http-cookie-lifetime=1s \
    split-user-domain=no \
    use-radius=no

# 6. Setup Hotspot Server
:log info "Kahf WiFi: Creating hotspot server..."
/ip hotspot add name="kahf-wifi-hotspot" \
    interface=$bridgeName \
    address-pool=$poolName \
    profile="kahf-wifi-profile" \
    disabled=no

# 7. Create Hotspot User Profile (5 min session)
:log info "Kahf WiFi: Creating user profile..."
/ip hotspot user profile add name="kahf-guest-profile" \
    session-timeout=$sessionTimeout \
    idle-timeout=00:05:00 \
    keepalive-timeout=00:02:00 \
    shared-users=unlimited \
    rate-limit="2M/2M" \
    add-mac-cookie=no

# 8. Create Guest User
:log info "Kahf WiFi: Creating guest user..."
/ip hotspot user add name=guest password=guest profile="kahf-guest-profile" comment="Kahf Free WiFi Guest"

# 9. Setup Walled Garden (allow before authentication)
:log info "Kahf WiFi: Configuring walled garden..."

# Block Apple captive portal detection (forces full browser)
/ip hotspot walled-garden add dst-host="captive.apple.com" action=deny comment="Force iOS full browser"

# Allow GitHub Pages (splash page)
/ip hotspot walled-garden ip add dst-address=185.199.108.0/22 action=accept comment="GitHub Pages"

# Allow Google Fonts
/ip hotspot walled-garden add dst-host="fonts.googleapis.com" action=accept comment="Google Fonts"
/ip hotspot walled-garden add dst-host="fonts.gstatic.com" action=accept comment="Google Fonts Static"

# Allow YouTube for video ads
/ip hotspot walled-garden add dst-host="*.youtube.com" action=accept comment="YouTube"
/ip hotspot walled-garden add dst-host="*.ytimg.com" action=accept comment="YouTube Images"
/ip hotspot walled-garden add dst-host="*.googlevideo.com" action=accept comment="Google Video"
/ip hotspot walled-garden ip add dst-address=172.217.0.0/16 action=accept comment="Google/YouTube IPs"
/ip hotspot walled-garden ip add dst-address=142.250.0.0/16 action=accept comment="Google IPs"
/ip hotspot walled-garden ip add dst-address=216.58.0.0/16 action=accept comment="Google IPs"
/ip hotspot walled-garden ip add dst-address=142.251.0.0/16 action=accept comment="Google IPs"

# Allow Kahf domains
/ip hotspot walled-garden add dst-host="*.kahf.com.tr" action=accept comment="Kahf Main"
/ip hotspot walled-garden add dst-host="*.kahfguard.com" action=accept comment="KahfGuard"
/ip hotspot walled-garden add dst-host="*.kahfbrowser.com" action=accept comment="Kahf Browser"
/ip hotspot walled-garden add dst-host="*.kahfinternet.com" action=accept comment="Kahf Internet"
/ip hotspot walled-garden add dst-host="dns.kahfguard.com" action=accept comment="Kahf DNS Assets"

# 10. Setup NAT for internet access
:log info "Kahf WiFi: Configuring NAT..."
/ip firewall nat add chain=srcnat src-address=$networkCIDR action=masquerade comment="Kahf Free WiFi NAT"

# 11. Create login.html for redirection to external splash page
:log info "Kahf WiFi: Creating login page..."

# Ensure hotspot directory exists
/file print file=flash/hotspot/test
:delay 1s
/file remove [find name="flash/hotspot/test.txt"]

# Create login.html with meta-refresh redirect (iOS compatible)
/file print file=flash/hotspot/login
:delay 1s

:local loginHTML "<!DOCTYPE html>\r\
\n<html>\r\
\n<head>\r\
\n    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\r\
\n    <meta http-equiv=\"pragma\" content=\"no-cache\">\r\
\n    <meta http-equiv=\"expires\" content=\"-1\">\r\
\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\r\
\n    <meta http-equiv=\"refresh\" content=\"0;url=$splashPageURL\?link-login=\$(link-login-only)&link-orig=\$(link-orig-esc)&mac=\$(mac)&ip=\$(ip)&error=\$(error)\">\r\
\n    <title>Connecting...</title>\r\
\n    <style>\r\
\n        body {\r\
\n            font-family: -apple-system, sans-serif;\r\
\n            display: flex;\r\
\n            justify-content: center;\r\
\n            align-items: center;\r\
\n            height: 100vh;\r\
\n            margin: 0;\r\
\n            background: #f8faf9;\r\
\n            color: #111;\r\
\n            text-align: center;\r\
\n        }\r\
\n    </style>\r\
\n</head>\r\
\n<body>\r\
\n    <div>\r\
\n        <h2>Connecting to WiFi...</h2>\r\
\n        <p>If not redirected, <a href=\"$splashPageURL\?link-login=\$(link-login-only)&link-orig=\$(link-orig-esc)&mac=\$(mac)&ip=\$(ip)\" style=\"color:#00c851;\">tap here</a></p>\r\
\n    </div>\r\
\n</body>\r\
\n</html>"

# Note: The login.html file needs to be uploaded manually via FTP/Files
# The script above creates a placeholder - upload the actual file from:
# https://github.com/alamin-mahamud/captive-portal-poc/blob/main/mikrotik-login-ios.html

:log info "Kahf WiFi: Setup complete!"
:log info "Kahf WiFi: IMPORTANT - Upload login.html to flash/hotspot/ manually"
:log info "Kahf WiFi: Now add interface '$hotspotInterface' to bridge '$bridgeName'"

# Print summary
:put ""
:put "=========================================="
:put "  Kahf Free WiFi Setup Complete!"
:put "=========================================="
:put ""
:put "Next Steps:"
:put "1. Add your WiFi interface to the bridge:"
:put "   /interface bridge port add bridge=$bridgeName interface=$hotspotInterface"
:put ""
:put "2. Upload login.html to flash/hotspot/ via Files/FTP"
:put "   Download from: https://github.com/alamin-mahamud/captive-portal-poc"
:put ""
:put "3. Test by connecting to WiFi"
:put ""
:put "Configuration:"
:put "  - Network: $networkCIDR"
:put "  - Gateway: $gatewayIP"
:put "  - Session: $sessionTimeout"
:put "  - Splash: $splashPageURL"
:put ""
