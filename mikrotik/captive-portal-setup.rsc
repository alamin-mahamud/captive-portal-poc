#───────────────────────────────────────────────────────────────────────────────
# MIKROTIK CAPTIVE PORTAL - PORTABLE CONFIGURATION SCRIPT
#
# Version: 1.0.0
# Compatible with: RouterOS 6.x and 7.x
#
# Usage:
#   1. Edit CONFIGURATION VARIABLES section below
#   2. Upload this file to MikroTik (Files menu)
#   3. Run: /import captive-portal-setup.rsc
#
# Or copy-paste into terminal after editing variables.
#───────────────────────────────────────────────────────────────────────────────

#═══════════════════════════════════════════════════════════════════════════════
#  CONFIGURATION VARIABLES - EDIT THESE BEFORE RUNNING!
#═══════════════════════════════════════════════════════════════════════════════

:global cpBridgeName "bridge-hotspot"
:global cpBridgeIP "192.168.50.1"
:global cpNetworkPrefix "192.168.50"
:global cpDhcpPoolStart "192.168.50.100"
:global cpDhcpPoolEnd "192.168.50.254"
:global cpHotspotName "kahf-wifi"
:global cpWifiSSID "Kahf Free WiFi"
:global cpWifiPassword ""
:global cpSplashPageURL "https://alamin-mahamud.github.io/captive-portal-poc/"
:global cpSessionTimeout "00:05:00"
:global cpDhcpLeaseTime "00:05:00"
:global cpWifiInterface "wlan1"
:global cpLanPorts {"ether2";"ether3";"ether4"}

#═══════════════════════════════════════════════════════════════════════════════
#  STEP 1: CREATE BRIDGE
#═══════════════════════════════════════════════════════════════════════════════

:log info "CP Setup: Creating bridge..."

# Remove existing bridge if exists (optional - uncomment if needed)
# /interface bridge remove [find name=$cpBridgeName]

/interface bridge add name=$cpBridgeName comment="Captive Portal Bridge - Auto Generated"

:foreach port in=$cpLanPorts do={
    :do {
        /interface bridge port add bridge=$cpBridgeName interface=$port
        :log info "CP Setup: Added $port to bridge"
    } on-error={
        :log warning "CP Setup: Could not add $port to bridge (may already exist)"
    }
}

:do {
    :if ([:len [/interface wireless find name=$cpWifiInterface]] > 0) do={
        /interface bridge port add bridge=$cpBridgeName interface=$cpWifiInterface
        :log info "CP Setup: Added $cpWifiInterface to bridge"
    }
} on-error={
    :log warning "CP Setup: Could not add wireless interface (may already exist)"
}

#═══════════════════════════════════════════════════════════════════════════════
#  STEP 2: ASSIGN IP ADDRESS
#═══════════════════════════════════════════════════════════════════════════════

:log info "CP Setup: Assigning IP address..."

:do {
    /ip address add address="$cpBridgeIP/24" interface=$cpBridgeName comment="Hotspot Gateway - Auto Generated"
} on-error={
    :log warning "CP Setup: IP address may already exist"
}

#═══════════════════════════════════════════════════════════════════════════════
#  STEP 3: CREATE DHCP SERVER
#═══════════════════════════════════════════════════════════════════════════════

:log info "CP Setup: Creating DHCP server..."

:do {
    /ip pool add name="pool-$cpHotspotName" ranges="$cpDhcpPoolStart-$cpDhcpPoolEnd"
} on-error={
    :log warning "CP Setup: Pool may already exist"
}

:do {
    /ip dhcp-server add name="dhcp-$cpHotspotName" interface=$cpBridgeName \
        address-pool="pool-$cpHotspotName" lease-time=$cpDhcpLeaseTime disabled=no
} on-error={
    :log warning "CP Setup: DHCP server may already exist"
}

:do {
    /ip dhcp-server network add address="$cpNetworkPrefix.0/24" gateway=$cpBridgeIP \
        dns-server=$cpBridgeIP comment="Hotspot Network - Auto Generated"
} on-error={
    :log warning "CP Setup: DHCP network may already exist"
}

#═══════════════════════════════════════════════════════════════════════════════
#  STEP 4: CONFIGURE WIRELESS
#═══════════════════════════════════════════════════════════════════════════════

:log info "CP Setup: Configuring wireless..."

:if ([:len [/interface wireless find name=$cpWifiInterface]] > 0) do={
    /interface wireless set $cpWifiInterface mode=ap-bridge ssid=$cpWifiSSID disabled=no

    :if ([:len $cpWifiPassword] > 0) do={
        /interface wireless security-profiles set default \
            authentication-types=wpa2-psk mode=dynamic-keys \
            wpa2-pre-shared-key=$cpWifiPassword
        :log info "CP Setup: WiFi configured with password"
    } else={
        /interface wireless security-profiles set default \
            authentication-types="" mode=none
        :log info "CP Setup: WiFi configured as open network"
    }
} else={
    :log info "CP Setup: No wireless interface found, skipping"
}

#═══════════════════════════════════════════════════════════════════════════════
#  STEP 5: CREATE HOTSPOT
#═══════════════════════════════════════════════════════════════════════════════

:log info "CP Setup: Creating hotspot..."

:do {
    /ip hotspot profile add name="hsprof-$cpHotspotName" \
        html-directory=hotspot \
        http-cookie-lifetime=1d \
        hotspot-address=$cpBridgeIP \
        login-by=http-chap,http-pap \
        use-radius=no
} on-error={
    :log warning "CP Setup: Hotspot profile may already exist"
}

:do {
    /ip hotspot add name=$cpHotspotName \
        interface=$cpBridgeName \
        address-pool="pool-$cpHotspotName" \
        profile="hsprof-$cpHotspotName" \
        disabled=no
} on-error={
    :log warning "CP Setup: Hotspot may already exist"
}

/ip hotspot user profile set default \
    session-timeout=$cpSessionTimeout \
    idle-timeout=$cpSessionTimeout \
    shared-users=unlimited

#═══════════════════════════════════════════════════════════════════════════════
#  STEP 6: CREATE GUEST USER
#═══════════════════════════════════════════════════════════════════════════════

:log info "CP Setup: Creating guest user..."

:do {
    /ip hotspot user add name=guest password=guest server=$cpHotspotName profile=default \
        comment="Auto-login guest account"
} on-error={
    :log warning "CP Setup: Guest user may already exist"
}

#═══════════════════════════════════════════════════════════════════════════════
#  STEP 7: CONFIGURE WALLED GARDEN
#═══════════════════════════════════════════════════════════════════════════════

:log info "CP Setup: Configuring walled garden..."

# Clear existing walled garden entries for clean setup
# /ip hotspot walled-garden ip remove [find comment~"Auto Generated"]
# /ip hotspot walled-garden remove [find comment~"Auto Generated"]

# GitHub Pages
/ip hotspot walled-garden ip add dst-host="*.github.io" action=accept comment="GitHub Pages - Auto Generated"
/ip hotspot walled-garden ip add dst-host="*.githubusercontent.com" action=accept comment="GitHub Assets - Auto Generated"

# Google Fonts & Assets
/ip hotspot walled-garden ip add dst-host="*.googleapis.com" action=accept comment="Google Fonts - Auto Generated"
/ip hotspot walled-garden ip add dst-host="*.gstatic.com" action=accept comment="Google Static - Auto Generated"

# YouTube
/ip hotspot walled-garden ip add dst-host="*.youtube.com" action=accept comment="YouTube - Auto Generated"
/ip hotspot walled-garden ip add dst-host="*.ytimg.com" action=accept comment="YouTube Images - Auto Generated"
/ip hotspot walled-garden ip add dst-host="*.googlevideo.com" action=accept comment="YouTube Video - Auto Generated"
/ip hotspot walled-garden ip add dst-host="*.ggpht.com" action=accept comment="Google Photos - Auto Generated"

# Kahf Assets
/ip hotspot walled-garden ip add dst-host="*.kahfguard.com" action=accept comment="Kahf DNS - Auto Generated"
/ip hotspot walled-garden ip add dst-host="*.kahf.com.tr" action=accept comment="Kahf Main - Auto Generated"

# Android Portal Detection
/ip hotspot walled-garden ip add dst-host="connectivitycheck.gstatic.com" action=accept comment="Android Check - Auto Generated"
/ip hotspot walled-garden ip add dst-host="connectivitycheck.android.com" action=accept comment="Android Check - Auto Generated"
/ip hotspot walled-garden ip add dst-host="clients3.google.com" action=accept comment="Android 204 - Auto Generated"

# iOS Portal Detection (DENY to trigger CNA)
/ip hotspot walled-garden add dst-host="captive.apple.com" action=deny comment="iOS CNA Trigger - Auto Generated"
/ip hotspot walled-garden add dst-host="*.apple.com" dst-port=80 action=deny comment="iOS CNA Trigger - Auto Generated"

#═══════════════════════════════════════════════════════════════════════════════
#  STEP 8: CONFIGURE EXTERNAL SPLASH PAGE
#═══════════════════════════════════════════════════════════════════════════════

:log info "CP Setup: Setting external splash page..."

/ip hotspot profile set "hsprof-$cpHotspotName" \
    login-url="$cpSplashPageURL?link-login=http://$cpBridgeIP/login&link-orig=\$(link-orig)"

#═══════════════════════════════════════════════════════════════════════════════
#  STEP 9: CONFIGURE NAT
#═══════════════════════════════════════════════════════════════════════════════

:log info "CP Setup: Configuring NAT..."

:do {
    /ip firewall nat add chain=srcnat src-address="$cpNetworkPrefix.0/24" \
        action=masquerade comment="Hotspot NAT - Auto Generated"
} on-error={
    :log warning "CP Setup: NAT rule may already exist"
}

#═══════════════════════════════════════════════════════════════════════════════
#  STEP 10: CONFIGURE LOGGING
#═══════════════════════════════════════════════════════════════════════════════

:log info "CP Setup: Configuring session logging..."

/ip hotspot user profile set default \
    on-login=":log info \"HOTSPOT-LOGIN: user=\$user mac=\$\"mac-address\" ip=\$address\"" \
    on-logout=":log info \"HOTSPOT-LOGOUT: user=\$user mac=\$\"mac-address\" session=\$\"session-time\"\"; :delay 1s; /ip hotspot host remove [find mac-address=\$\"mac-address\"]"

#═══════════════════════════════════════════════════════════════════════════════
#  CLEANUP GLOBAL VARIABLES
#═══════════════════════════════════════════════════════════════════════════════

:set cpBridgeName
:set cpBridgeIP
:set cpNetworkPrefix
:set cpDhcpPoolStart
:set cpDhcpPoolEnd
:set cpHotspotName
:set cpWifiSSID
:set cpWifiPassword
:set cpSplashPageURL
:set cpSessionTimeout
:set cpDhcpLeaseTime
:set cpWifiInterface
:set cpLanPorts

#═══════════════════════════════════════════════════════════════════════════════
#  COMPLETE!
#═══════════════════════════════════════════════════════════════════════════════

:log info "═══════════════════════════════════════════════════════════════════"
:log info "  CAPTIVE PORTAL SETUP COMPLETE!"
:log info "═══════════════════════════════════════════════════════════════════"
:log info "  Check /ip hotspot print to verify"
:log info "  Check /log print to see session activity"
:log info "═══════════════════════════════════════════════════════════════════"
