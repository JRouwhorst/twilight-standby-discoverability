#!/system/bin/sh
MODDIR=${0%/*}
LOCK=twilight_ethernet_standby
exec > "$MODDIR/status.log" 2>&1
date
if [ -e "$MODDIR/disable" ] || [ -e "$MODDIR/remove" ]; then
    echo "Module disabled or pending removal; no lock acquired."
    exit 0
fi
if [ ! -w /sys/power/wake_lock ]; then
    echo "ERROR: /sys/power/wake_lock is unavailable or not writable."
    exit 1
fi
# No timeout: retained until explicitly released or the device reboots.
if ! echo "$LOCK" > /sys/power/wake_lock; then
    echo "ERROR: kernel wakelock acquisition failed."
    exit 1
fi
if grep -qw "$LOCK" /sys/power/wake_lock; then
    echo "ACTIVE: $LOCK"
else
    echo "ERROR: lock not found in active kernel wakelocks."
    exit 1
fi
