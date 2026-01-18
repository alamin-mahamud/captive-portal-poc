# MikroTik Captive Portal - Working Configuration v1.0.0
# Exported from router: 113.11.42.199

# === WALLED GARDEN ===
# 2026-01-18 15:39:54 by RouterOS 7.19.5
# software id = IWIE-EMV7
#
# model = RB951Ui-2HnD
# serial number = HKB0AX84RXQ
/ip hotspot walled-garden
add dst-host=*.github.io
add dst-host=*.githubusercontent.com
add dst-host=*.googleapis.com
add dst-host=*.gstatic.com
add dst-host=*.google.com
add dst-host=*.youtube.com
add dst-host=*.ytimg.com
add dst-host=*.googlevideo.com
add dst-host=*.ggpht.com
add dst-host=*.kahfguard.com
add dst-host=*.googleusercontent.com
add action=deny dst-host=captive.apple.com

# === HOTSPOT ===
# 2026-01-18 15:39:54 by RouterOS 7.19.5
# software id = IWIE-EMV7
#
# model = RB951Ui-2HnD
# serial number = HKB0AX84RXQ
/ip hotspot profile
add hotspot-address=192.168.0.1 login-by=http-chap,http-pap name=hsprof-kahf
/ip hotspot
add address-pool=dhcp_pool0 disabled=no interface=bridge1 name=kahf-hotspot \
    profile=hsprof-kahf
/ip hotspot user profile
set [ find default=yes ] idle-timeout=5m on-login=":log info \"HOTSPOT-LOGIN: \
    user=\$user mac=\$\"mac-address\" ip=\$address\"" on-logout=":log info \"H\
    OTSPOT-LOGOUT: user=\$user mac=\$\"mac-address\"\"; :delay 1s; /ip hotspot\
    \_host remove [find mac-address=\$\"mac-address\"]" session-timeout=5m \
    shared-users=unlimited
/ip hotspot user
add comment="Auto-login guest" name=guest server=kahf-hotspot
/ip hotspot walled-garden
add dst-host=*.github.io
add dst-host=*.githubusercontent.com
add dst-host=*.googleapis.com
add dst-host=*.gstatic.com
add dst-host=*.google.com
add dst-host=*.youtube.com
add dst-host=*.ytimg.com
add dst-host=*.googlevideo.com
add dst-host=*.ggpht.com
add dst-host=*.kahfguard.com
add dst-host=*.googleusercontent.com
add action=deny dst-host=captive.apple.com

# === HOTSPOT PROFILE ===
# 2026-01-18 15:39:54 by RouterOS 7.19.5
# software id = IWIE-EMV7
#
# model = RB951Ui-2HnD
# serial number = HKB0AX84RXQ
/ip hotspot profile
add hotspot-address=192.168.0.1 login-by=http-chap,http-pap name=hsprof-kahf

# === HOTSPOT USER ===
# 2026-01-18 15:39:54 by RouterOS 7.19.5
# software id = IWIE-EMV7
#
# model = RB951Ui-2HnD
# serial number = HKB0AX84RXQ
/ip hotspot user profile
set [ find default=yes ] idle-timeout=5m on-login=":log info \"HOTSPOT-LOGIN: \
    user=\$user mac=\$\"mac-address\" ip=\$address\"" on-logout=":log info \"H\
    OTSPOT-LOGOUT: user=\$user mac=\$\"mac-address\"\"; :delay 1s; /ip hotspot\
    \_host remove [find mac-address=\$\"mac-address\"]" session-timeout=5m \
    shared-users=unlimited
/ip hotspot user
add comment="Auto-login guest" name=guest server=kahf-hotspot

# === HOTSPOT USER PROFILE ===
# 2026-01-18 15:39:54 by RouterOS 7.19.5
# software id = IWIE-EMV7
#
# model = RB951Ui-2HnD
# serial number = HKB0AX84RXQ
/ip hotspot user profile
set [ find default=yes ] idle-timeout=5m on-login=":log info \"HOTSPOT-LOGIN: \
    user=\$user mac=\$\"mac-address\" ip=\$address\"" on-logout=":log info \"H\
    OTSPOT-LOGOUT: user=\$user mac=\$\"mac-address\"\"; :delay 1s; /ip hotspot\
    \_host remove [find mac-address=\$\"mac-address\"]" session-timeout=5m \
    shared-users=unlimited
