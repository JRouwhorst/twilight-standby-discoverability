#!/system/bin/sh
if [ -w /sys/power/wake_unlock ]; then
    echo twilight_ethernet_standby > /sys/power/wake_unlock 2>/dev/null
fi
exit 0
