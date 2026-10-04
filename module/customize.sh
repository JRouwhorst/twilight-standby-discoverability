#!/system/bin/sh
[ "$BOOTMODE" = true ] || abort "Install from running Android using Magisk."
[ -w /sys/power/wake_lock ] || abort "Kernel wakelock interface unavailable or not writable."
[ -w /sys/power/wake_unlock ] || abort "Kernel wake_unlock interface unavailable or not writable."
ui_print "- Hold one kernel wakelock at each boot"
ui_print "- Higher standby power use; no framework/property changes"
ui_print "- Reboot to activate; disable and reboot to stop"
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
