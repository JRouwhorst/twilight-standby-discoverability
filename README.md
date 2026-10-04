# Twilight Standby Discoverability

**[Download the module](https://github.com/JRouwhorst/twilight-standby-discoverability/releases/latest)** · **[Report an issue](https://github.com/JRouwhorst/twilight-standby-discoverability/issues)** · **[♡ Support this project](#support-this-project)**

Keep the **Xiaomi TV Box S 3rd Gen** discoverable and reachable for casting during standby over **Wi-Fi or USB Ethernet**, using a small Magisk module.

**Version:** 1.1 · **Guide updated:** October 4, 2026 · **Terminal:** Windows PowerShell

The module holds a single kernel wakelock. Android can become non-interactive and continue its normal standby handling, while normal system suspend is prevented. Working standby connectivity has been reported over both Wi-Fi and USB Ethernet. Standby power consumption increases; the lock remains active regardless of which network connection is in use, including when no network is connected.

Previously named **Twilight Ethernet Standby**. Version 1.1 updates the display name and description to reflect Wi-Fi support; the wakelock behavior is unchanged. The internal module ID and lock name remain `twilight_ethernet_standby` so an existing v1.0 installation can be updated as the same module. Those legacy names in commands and logs do not limit it to Ethernet.

## Quick navigation

- **Magisk/root already works:** start with [A — Install the module](#a--install-the-module).
- **Not rooted yet:** read [B — Separate section: rooting](#b--separate-section-rooting), then return to A.
- **Undo the changes:** see [C — Disable and uninstall](#c--disable-and-uninstall).
- **Previously applied power tweaks:** see [D — Settings and troubleshooting](#d--settings-and-troubleshooting).

## Tested configuration and evidence

| Component | Tested value |
|---|---|
| Model | Xiaomi TV Box S 3rd Gen, `MiTV-AFMU0` |
| Product name | `twilight` |
| Platform | Amlogic `s7d` |
| Firmware | `V816.0.11.0.UZFAABX` |
| Android | 14 |
| Build | `UKG3.250826.001` |
| Magisk | 30.7 |
| Userspace ABI | `armeabi-v7a` |
| USB Ethernet adapter | AX88179B, USB ID `0b95:1790` |
| Ethernet interface | `eth1` on the test device |
| Wi-Fi | Standby operation also confirmed by the user |

During the original USB Ethernet test, IP connectivity disappeared almost immediately on entering standby and returned on wake. A successful Ethernet/Cast test was reported with a temporary kernel wakelock, including with Xiaomi's ten-second timeout. The v1.0 module was subsequently installed successfully, and its active kernel wakelock was verified after a reboot. The user also confirmed that the solution works over Wi-Fi. Version 1.1 retains the same startup and wakelock scripts; installation of this renamed package has not been separately tested on hardware.

The most recently checked configuration had **Deep Doze, Light Doze, and Low Power Standby enabled**. The previously used package `eu.thedarken.wldonate` was no longer installed or present in the idle whitelist. A separate extended Cast/CEC test following that final check has not yet been recorded. This is a reproducible approach for the tested combination, not a guarantee for every adapter, build, or HDMI setup. The additional power consumption has not been measured.

## Requirements

- A box matching the identification above, connected through Wi-Fi or a working USB Ethernet adapter.
- A Windows PC with [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools), for example extracted to `C:\platform-tools`.
- Working ADB access through **wireless ADB or USB ADB** and, for section A, working Magisk root.
- A **USB-A-to-USB-A data cable for the fastboot steps in B3 and B5**. If Magisk root already works, the module can be installed using wireless ADB without this cable.
- The included **`Twilight-Standby-Discoverability-v1.1.zip`** file.

Use PowerShell and copy only the commands, not a `PS C:\...>` prompt. The examples assume exactly one connected Android device. If multiple devices are connected, explicitly select the intended device using `adb -s`.

The module ZIP is the installation ZIP. If you have a sharing bundle containing this README as well, extract that bundle first; do not install the outer bundle directly in Magisk.

## Choose your connection: wireless ADB or USB

**Wireless ADB can replace the USB-A-to-USB-A cable for every ADB step in this guide while Android is running**, including checking the device, transferring files, patching the image on the box, installing the module, and reading its status.

**Exception: the fastboot steps require a physical USB data connection to the PC.** Wireless ADB cannot carry out the unlocking or flashing commands in B3 and B5. You may send `adb reboot bootloader` wirelessly, but ADB disconnects when the box enters the bootloader. From there, use the USB cable and `fastboot`. Technically this is **fastboot over USB**, not USB ADB; `fastboot devices` must detect the box.

### Set up wireless ADB

Keep the PC and box on the same Wi-Fi network. In Developer options, enable **Wireless debugging** and select **Pair device with pairing code**. In PowerShell:

```powershell
.\adb pair BOX-IP:PAIRING-PORT
.\adb connect BOX-IP:CONNECTION-PORT
.\adb devices
```

Replace the placeholders with the values shown on the box. Enter the pairing code when prompted. Use the pairing dialog's port for `pair` and the main Wireless debugging screen's port for `connect`; these may differ. Once connected, the guide's ADB commands work unchanged. After a reboot, reconnect if necessary; after an unlock/reset, you may need to enable debugging and pair again. See [Android's wireless ADB instructions](https://developer.android.com/tools/adb#connect-to-a-device-over-wi-fi).

Wireless debugging and USB debugging are separate settings. **USB debugging must still be off for USB Ethernet on the tested box.** A wireless ADB connection may disappear when switching networks or entering standby; do not rely on it remaining available during an Ethernet test. Disconnect ADB before testing standby behavior.

## Important: switch USB debugging when changing USB connections

**On the tested box, the USB Ethernet adapter does not work while USB debugging is enabled.** When switching between USB ADB and USB Ethernet, you must also toggle **USB debugging** in the box's Developer options. Swapping the cable alone is not enough.

| What you want to use | USB debugging |
|---|---|
| USB ADB connection to the PC | **On** — connect the PC and approve authorization if prompted |
| USB Ethernet adapter | **Off** — connect the adapter and wait for the Ethernet connection |

To switch from USB ADB to Ethernet: finish the ADB commands, turn **USB debugging off** using the remote, disconnect the PC's USB cable, and connect the Ethernet adapter. To return to USB ADB: disconnect the Ethernet adapter, turn **USB debugging on**, reconnect the PC, and check `adb devices`.

This requirement was reported on the tested hardware/firmware. The module does not toggle USB debugging for you. It concerns the USB debugging setting specifically; it is not an instruction to disable Wi-Fi for normal Wi-Fi use. If Ethernet is unavailable even while the box is awake, check USB debugging before investigating standby behavior.

## A — Install the module

### A1. Verify root

Place the module ZIP in `C:\platform-tools` and open PowerShell there:

```powershell
cd C:\platform-tools
.\adb devices
.\adb shell /debug_ramdisk/su -c id
```

Grant the shell's root request if Magisk prompts you. Expected output includes:

```text
uid=0(root) gid=0(root) ... context=u:r:magisk:s0
```

The absolute paths `/debug_ramdisk/su` and `/debug_ramdisk/magisk` worked on the tested firmware. If they are missing, check your Magisk installation first; do not continue without confirmed root access.

Also check the kernel interface:

```powershell
.\adb shell /debug_ramdisk/su -c 'ls -l /sys/power/wake_lock /sys/power/wake_unlock'
```

Both files must exist. The module installer stops if these interfaces are not writable.

### A2. Optional: run a five-minute test first

This test does not create a persistent boot setting:

```powershell
.\adb shell "/debug_ramdisk/su -c 'echo discoverability_test 300000000000 > /sys/power/wake_lock && cat /sys/power/wake_lock'"
```

Check that `discoverability_test` appears. Connect using the network you want to test, put the box into standby, and test ping and a new Cast connection within five minutes. The time unit is nanoseconds; the lock expires automatically. Test each connection separately: disconnect USB Ethernet for a Wi-Fi test, or turn Wi-Fi off for an Ethernet test, so the result clearly applies to the selected connection.

**Only one USB port and testing Ethernet?** Run the command using USB ADB or wireless ADB while the box is awake. If using wireless ADB, disconnect it before the standby test. Then turn **USB debugging off** in Developer options using the remote, replace the PC's USB connection with the Ethernet adapter, and test from your PC/phone before the five-minute lock expires. ADB does not need to stay connected during the test. To read results through USB ADB afterward, disconnect the adapter, turn USB debugging back on, and reconnect the PC. For a Wi-Fi test, keep the box on Wi-Fi and disconnect ADB before testing so the debugging connection does not influence the result.

### A3. Install the module

**Updating from v1.0?** Install v1.1 using the same steps below and reboot. The internal ID is unchanged, so it updates the existing module rather than creating a second one. You do not need to root again. The change is naming and documentation only; v1.0 already uses the same wakelock mechanism for Wi-Fi and Ethernet.

Optionally verify the ZIP:

```powershell
Get-FileHash .\Twilight-Standby-Discoverability-v1.1.zip -Algorithm SHA256
```

SHA-256 of the included v1.1 module ZIP:

```text
2DCAC74AEA6250F1AAF5C850F6CBD141363D349EF480A6FD2C3D0C82122A272D
```

Install using Magisk:

```powershell
.\adb push .\Twilight-Standby-Discoverability-v1.1.zip /data/local/tmp/Twilight-Standby-Discoverability-v1.1.zip
.\adb shell "/debug_ramdisk/su -c '/debug_ramdisk/magisk --install-module /data/local/tmp/Twilight-Standby-Discoverability-v1.1.zip'"
```

Wait for successful installation, ending with `Done`. Then reboot:

```powershell
.\adb reboot
```

Magisk documents this installation command in [Magisk Tools](https://topjohnwu.github.io/Magisk/tools.html). You can also install through the Magisk app if the Android file picker works; the ADB method avoids that file picker.

### A4. Verify automatic startup

After booting, completing any required unlock/setup, and reconnecting ADB:

```powershell
.\adb shell "/debug_ramdisk/su -c 'cat /data/adb/modules/twilight_ethernet_standby/status.log; cat /sys/power/wake_lock'"
```

Expect a date followed by:

```text
ACTIVE: twilight_ethernet_standby
twilight_ethernet_standby
```

Other active lock names may also appear. The first line confirms the script's startup check; the second readout confirms that the lock is currently active. A reboot removes the temporary `discoverability_test` lock; the module uses its own name.

### A5. Test the result

1. Connect through Wi-Fi or USB Ethernet and verify Internet access while the box is awake. **For USB Ethernet, first turn USB debugging off**, disconnect the PC's USB cable, and connect the adapter. Test one network connection at a time, with the other disconnected or disabled.
2. Use the current **IP address of the connection being tested** from network settings; Ethernet and Wi-Fi may have different addresses.
3. Put the box into standby normally.
4. Test a new Cast connection after 30 seconds, two minutes, and more than ten minutes.
5. Optionally run `ping -n 4 IP-ADDRESS`, replacing `IP-ADDRESS` with the actual address.
6. Also check turning the TV off/on through CEC and using the remote.
7. Repeat after another reboot and a longer standby period. If you use both Wi-Fi and Ethernet, repeat the test separately for each.

This module does not write CEC settings. Actual behavior still depends on the existing TV/box settings and must be checked on your own setup.

If you need another USB ADB check, disconnect the Ethernet adapter, turn USB debugging back on, and reconnect the PC. Turn it off again before resuming USB Ethernet use. The installed module remains active when USB debugging is switched off.

## B — Separate section: rooting

**Skip this section if Magisk root already works.** This section records the procedure used on the test device. Rooting and unlocking are much more invasive than the module itself: unlocking the bootloader can erase user data, and an incorrect boot image can prevent the device from booting. Back up your data and obtain the correct stock image first. Do not assume you have a usable second slot or an easy recovery method without checking.

Android describes data erasure during unlocking in its [bootloader documentation](https://source.android.com/docs/core/architecture/bootloader/locking_unlocking). This tutorial does not automate unlocking or flashing: perform the steps separately and check each result.

### B1. Record the device identity and firmware

Enable Developer options by repeatedly selecting the build number in device settings; menu names may vary. Enable OEM unlocking. For ADB, either enable USB debugging and authorize the PC, or set up Wireless debugging as described above. Wireless ADB works for these Android steps; the later fastboot steps still need the USB data cable.

```powershell
cd C:\platform-tools
.\adb devices
.\adb shell getprop ro.product.model
.\adb shell getprop ro.product.name
.\adb shell getprop ro.board.platform
.\adb shell getprop ro.product.cpu.abi
.\adb shell getprop ro.build.fingerprint
.\adb shell getprop ro.bootimage.build.date.utc
.\adb shell getprop ro.boot.slot_suffix
```

The tested responses were `MiTV-AFMU0`, `twilight`, `s7d`, `armeabi-v7a`, and:

```text
Xiaomi/twilight/twilight:14/UKG3.250826.001/V816.0.11.0.UZFAABX:user/release-keys
1785938030
_a
```

This tutorial has not been validated for a TV Stick or another generation. A matching codename alone does not make boot images interchangeable.

### B2. Prepare the correct stock image

Obtain a trusted OTA for **exactly the installed build**, and name the local file `Twilight_OTA.zip` for the examples below. The exact download URL of the OTA used in this test was not recorded in the terminal archive, so no guessed URL or firmware download is provided. Do not start flashing if you cannot verify matching firmware.

Compare the metadata, not just the ZIP filename:

```powershell
tar -xOf .\Twilight_OTA.zip META-INF/com/android/metadata | Select-String 'post-build=|post-timestamp='
```

For our build, `post-build` and `post-timestamp` matched the fingerprint and timestamp above. Stop if they do not match. If the box has received a firmware update in the meantime, obtain a matching image again.

Download [payload-dumper-go](https://github.com/ssut/payload-dumper-go/releases) for your PC's Windows architecture, extract it, and place `payload-dumper-go.exe` in the working directory. Renaming a Linux binary to `.exe` does not work. For this procedure, use a package from which the complete `init_boot` image can be successfully extracted; a delta requiring base images is outside this guide's scope.

Use a clean working directory for this firmware so an old image cannot be mistaken for new output:

```powershell
tar -xf .\Twilight_OTA.zip payload.bin
New-Item -ItemType Directory -Path .\extracted -ErrorAction Stop
.\payload-dumper-go.exe -o .\extracted -p init_boot .\payload.bin
```

Verify that extraction finished without errors before continuing. Then:

```powershell
Get-Item .\extracted\init_boot.img | Select-Object Name,Length
Get-FileHash .\extracted\init_boot.img -Algorithm SHA256
Copy-Item .\extracted\init_boot.img .\init_boot_stock_backup.img
```

For **the tested V816.0.11.0.UZFAABX image only**:

```text
Size: 8388608 bytes
SHA256: F5DDB14EB758F755F556C74A4379C403F08DE87103623F5156EA4B6F2119F531
```

Keep the backup and record its firmware version. Other firmware may have a different hash and requires its own verification. No stock or patched firmware image is included in this sharing bundle.

### B3. Unlock the bootloader

**A USB-A-to-USB-A data cable is required for this section.** Wireless ADB may be used to send `adb reboot bootloader`, but unlocking then uses **fastboot over USB**, not ADB. Connect the PC and box by USB before running the fastboot commands.

```powershell
.\adb reboot bootloader
.\fastboot devices
.\fastboot getvar current-slot
.\fastboot getvar unlocked
```

Continue only if fastboot detects your box. If it waits for a device, resolve the cable/USB connection and Windows driver first. Record the slot.

> **Windows fastboot driver note:** Platform Tools supplies `adb` and `fastboot`, but you may also need to install a compatible USB/bootloader driver. If `fastboot devices` is empty or a command waits for a device, open **Device Manager with the box connected by USB and in bootloader mode**. Find the Android/unknown device, choose **Update driver → Browse my computer for drivers**, and select the appropriate driver from a trusted manufacturer source. A correctly configured entry commonly appears as **Android Bootloader Interface**. Working ADB in Android does not guarantee that the bootloader driver is installed; wireless ADB does not use that driver at all. Recheck `fastboot devices` before unlocking or flashing. See [Android's Windows USB driver instructions and OEM links](https://developer.android.com/studio/run/oem-usb). The exact driver package used in our original test was not recorded.


The following commands were successfully executed on the test device:

```powershell
.\fastboot flashing unlock
```

Follow any confirmation prompt on the box; expect that user data may be erased. Once fastboot is available again:

```powershell
.\fastboot getvar unlocked
.\fastboot flashing unlock_critical
.\fastboot reboot
```

Expect `unlocked: yes` and successful command output. Set the box up again if needed, re-enable debugging, and authorize the PC. Check:

```powershell
.\adb shell getprop ro.boot.verifiedbootstate
.\adb shell getprop ro.build.fingerprint
```

On our box, the Verified Boot state became `orange`. Check again that the firmware still matches your prepared stock image. Do not switch slots blindly or relock with a modified image.

### B4. Install Magisk and patch init_boot on the box itself

Use the APK from the [official Magisk releases](https://github.com/topjohnwu/Magisk/releases). **30.7** was tested in this procedure; the filenames below refer to that version.

```powershell
.\adb install .\Magisk-v30.7.apk
```

Open the Magisk app once. The standard official procedure is to select and patch your own `init_boot.img` on the target device. The file picker did not work on our TV box, so we used the following ADB method with the scripts from the same APK. Use only your own matching stock image, not an image patched by someone else. See [Magisk installation](https://topjohnwu.github.io/Magisk/install.html).

Create fresh working directories; if these already exist, use a new working directory for this attempt:

```powershell
New-Item -ItemType Directory .\magisk_apk -ErrorAction Stop
New-Item -ItemType Directory .\mg -ErrorAction Stop
tar -xf .\Magisk-v30.7.apk -C .\magisk_apk

Copy-Item .\magisk_apk\assets\boot_patch.sh .\mg\boot_patch.sh
Copy-Item .\magisk_apk\assets\util_functions.sh .\mg\util_functions.sh
Copy-Item .\magisk_apk\assets\stub.apk .\mg\stub.apk
Copy-Item .\magisk_apk\lib\armeabi-v7a\libmagiskboot.so .\mg\magiskboot
Copy-Item .\magisk_apk\lib\armeabi-v7a\libmagiskinit.so .\mg\magiskinit
Copy-Item .\magisk_apk\lib\armeabi-v7a\libinit-ld.so .\mg\init-ld
Copy-Item .\magisk_apk\lib\armeabi-v7a\libmagisk.so .\mg\magisk
Copy-Item .\magisk_apk\lib\armeabi-v7a\libbusybox.so .\mg\busybox
Get-ChildItem .\mg
```

This selection is for the previously verified `armeabi-v7a` userspace. Stop if the ABI differs or the required APK files are missing.

Use a fresh staging directory on the box so an old `new-boot.img` cannot be reused after a failed patch:

```powershell
.\adb shell mkdir /data/local/tmp/twilight-root-stage
```

If this directory already exists, choose a new name and update all subsequent paths consistently. Continue only after successful creation:

```powershell
.\adb push .\mg\. /data/local/tmp/twilight-root-stage/
.\adb push .\extracted\init_boot.img /data/local/tmp/twilight-root-stage/init_boot.img
.\adb shell 'cd /data/local/tmp/twilight-root-stage && chmod 755 magiskboot magiskinit init-ld magisk busybox && sh ./boot_patch.sh ./init_boot.img'
```

Review the patch output. Our successful attempt reported `Stock boot image detected`, `Pre-init storage partition: metadata`, and repacking to `new-boot.img`. Stop on errors; never flash a file merely because it exists.

```powershell
.\adb shell ls -l /data/local/tmp/twilight-root-stage/new-boot.img
.\adb shell sha256sum /data/local/tmp/twilight-root-stage/new-boot.img
.\adb pull /data/local/tmp/twilight-root-stage/new-boot.img .\init_boot_magisk.img
Get-Item .\init_boot_magisk.img | Select-Object Name,Length
Get-FileHash .\init_boot_magisk.img -Algorithm SHA256
```

The hashes on the box and PC must match. Our patched image was 8388608 bytes. The patched hash can differ between patch environments; someone else's patched hash is no substitute for matching stock firmware and a successful patch on your own device.

### B5. Flash only init_boot on the verified active slot

**Reconnect the USB-A-to-USB-A data cable for this section.** Even if the image was patched and transferred using wireless ADB, flashing requires fastboot over USB. Wireless ADB cannot replace this connection.

```powershell
.\adb reboot bootloader
.\fastboot devices
.\fastboot getvar current-slot
.\fastboot getvar unlocked
```

Our device used slot `a`. **Only if `current-slot: a`**, with confirmed unlock and a verified image:

```powershell
.\fastboot flash init_boot_a .\init_boot_magisk.img
```

If your verified active slot is `b`, the destination is `init_boot_b` instead. Execute only the command for the correct slot. The slot B variant was not performed on our test device.

Verify both `Sending ... OKAY` and `Writing ... OKAY`, then:

```powershell
.\fastboot reboot
```

This procedure does not require flashing `boot`, `vbmeta`, `vendor_boot`, `dtbo`, or `super`. Do not flash other partitions as part of this tutorial.

Open Magisk, complete any requested additional setup, and allow another reboot if needed. Then check:

```powershell
.\adb shell /debug_ramdisk/su -c id
.\adb shell /debug_ramdisk/magisk -v
```

Root should report `uid=0(root)`. Now return to **section A** to install the standby discoverability module.

## C — Disable and uninstall

### The standby discoverability module only

Disable **Twilight Standby Discoverability** in Magisk and reboot. You can also remove it through Magisk and reboot. Toggling it off alone does not immediately release the current kernel lock. An older v1.0 installation appears as **Twilight Ethernet Standby**.

Alternatively, use ADB to mark the module as disabled and release the lock immediately:

```powershell
.\adb shell "/debug_ramdisk/su -c 'touch /data/adb/modules/twilight_ethernet_standby/disable && echo twilight_ethernet_standby > /sys/power/wake_unlock'"
.\adb reboot
```

The module remains installed but disabled. Re-enable it through Magisk and reboot if you want to use the solution again. Releasing a lock that is not active may produce an error; check the disabled status and reboot. This does not remove Magisk/root.

### Undo rooting

Magisk supports uninstalling through its app; consult the [official installation/uninstallation guide](https://topjohnwu.github.io/Magisk/install.html). If you restore a stock image manually, it must match the **currently installed firmware and the selected slot**. An old backup may no longer be suitable after an OTA.

Only when fastboot is accessible, the active slot has been checked again, and the stock backup still matches: the restore command for slot `a` is `fastboot flash init_boot_a init_boot_stock_backup.img` (in this PowerShell working directory, prefix both `fastboot` and the filename with `.\`). For slot `b`, use `init_boot_b` accordingly. This recovery path was not performed during the test. Restoring init_boot does not relock the bootloader. This tutorial does not include relocking or hardware recovery instructions.

## D — Settings and troubleshooting

### Required power adjustments

For a new, otherwise unmodified device, this tutorial prescribes **no additional power tweaks**. The module provides the standby behavior change. The most recently checked configuration was:

| Setting | Value |
|---|---|
| Device Idle deep | `1` |
| Device Idle light | `1` |
| `low_power_standby_enabled` | `1` |
| `persist.sys.str.forcesuspend` | `10000` |
| Previous Wakelock app / exception | Not present |

Check these only if you want to review earlier experiments:

```powershell
.\adb shell dumpsys deviceidle enabled deep
.\adb shell dumpsys deviceidle enabled light
.\adb shell settings get global low_power_standby_enabled
.\adb shell getprop persist.sys.str.forcesuspend
```

An **empty** forcesuspend property is also normal on this firmware: the code defaults to `10000`. You do not need to create a missing property. If you previously increased it yourself, you can return to the default duration on this tested firmware:

```powershell
.\adb shell /debug_ramdisk/su -c 'setprop persist.sys.str.forcesuspend 10000'
```

This restores the duration, not the property's original absence. Neither `0` nor `-1` disables this timer; do not use them to stop it.

Only if you deliberately disabled the modes earlier and want to reproduce the most recently checked configuration:

```powershell
.\adb shell dumpsys deviceidle enable all
.\adb shell settings put global low_power_standby_enabled 1
```

Read the values again afterward. The previous wakelock app is not required. This module does not require LSPosed, a framework patch, USB autosuspend changes, or disabling automatic updates.

### Common issues

| Issue | What to check |
|---|---|
| `more than one device/emulator` | **First disconnect and reconnect:** run `adb disconnect`, then `adb connect BOX-IP:CONNECTION-PORT`, and check `adb devices`. This clears existing network ADB connections, including stale ones. If multiple entries remain, unplug an unused USB connection or select the intended device using `adb -s`. See the commands below. |
| `unauthorized` | Approve ADB authorization on the box. |
| USB Ethernet does not work, even while awake | Turn **USB debugging off** in Developer options, disconnect the PC cable, and connect the Ethernet adapter. On the tested box, USB debugging must be off for USB Ethernet. |
| USB ADB stopped working after an Ethernet test | Disconnect the Ethernet adapter, turn **USB debugging on**, reconnect the PC, and approve authorization if prompted. |
| `no devices` / fastboot keeps waiting | Fastboot requires a physical USB data cable and a compatible Windows bootloader driver. Check Device Manager while the box is in fastboot and install/update the appropriate driver; see the Windows driver note in B3. Working wireless ADB does not verify USB drivers. A failed command did not apply the intended change. |
| No `status.log` after reboot | Check in Magisk that the module is installed and enabled, and that Magisk root works. |
| `ERROR` in `status.log` | Read the error and check the kernel interfaces; do not blindly change SELinux or permissions. |
| Lock active, but the box still disappears | Verify the IP of the connection being tested and test Wi-Fi and Ethernet separately. Check Wi-Fi signal/access-point settings or the USB adapter/link as appropriate. Confirm the firmware and hardware used. The lock cannot fix every driver or network problem. |
| Ping works, but Cast does not | Network reachability and Cast discovery are different. Check that devices are on the same LAN, guest-network/client isolation, and the Cast service. |
| Reachable, but power consumption is higher | Expected consequence: the box cannot enter normal full system suspend while the lock is active. |
| Stops working after a firmware update | Recheck root and the module lock; do not reuse old init_boot images blindly. OTA/root retention was not tested in this tutorial. |

### First fix for multiple ADB connections

For `more than one device/emulator`, first clear the existing network connections and reconnect only to the box:

```powershell
.\adb disconnect
.\adb connect BOX-IP:CONNECTION-PORT
.\adb devices
```

Use the current connection address from the box's Wireless debugging screen, not its pairing port. This removes network ADB connections, including stale ones; it does not remove pairing authorizations, disconnect USB devices, or stop emulators. If more than one entry remains, disconnect any unused USB connection or select the box explicitly with `adb -s DEVICE-ID ...`, using its exact ID from `adb devices`.

## E — Technical background

In the analyzed `services.jar`, the relevant logic is in `com.android.server.power.MitvOverseaPower` in `classes2.dex`. On entering sleep, `startForceSuspendOrShutdown(int)` reads `persist.sys.str.forcesuspend`, defaulting to 10000 ms. Message 6 sets `mForceSuspend=true`; this causes `PowerManagerService.updateSuspendBlockerLocked()` to disregard its framework wakelock blocker. This path does not directly call `PowerManagerService.forceSuspendInternal()`.

The module requests a kernel wakelock directly through `/sys/power/wake_lock`. In the test, this continued working beyond the ten-second action. `service.sh` requests the lock once, checks the active list, and exits. No polling process remains running. The `status.log` file is overwritten on the next startup.

The module does not change the separate `persist.sys.max_str_cnt` counter setting. In this firmware, `strShutdown()` can request shutdown when the counter reaches its threshold. The default in the inspected code is 30; long-term behavior across many sleep transitions has not been tested. Also, the name of the 60000 ms timer does not mean it actually shuts down the device in this firmware: the handler found only processes message 6.

The module ZIP contains readable scripts, metadata, `skip_mount`, and Magisk installation files. The installer comes from the Magisk APK used; preserve its attribution and applicable Magisk license terms when redistributing. The sharing bundle contains no firmware images, private terminal log, device serial numbers, pairing codes, or account details.

## Sources and provenance

The specific test results, firmware hash, slot checks, and command sequence come from our own terminal measurements on the box identified above. Additional references:

- [Magisk: installation and patching your own image](https://topjohnwu.github.io/Magisk/install.html).
- [Magisk: CLI commands](https://topjohnwu.github.io/Magisk/tools.html).
- [Magisk: module format and boot scripts](https://topjohnwu.github.io/Magisk/guides.html).
- [Android: bootloader locking/unlocking](https://source.android.com/docs/core/architecture/bootloader/locking_unlocking).
- [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools).
- [payload-dumper-go](https://github.com/ssut/payload-dumper-go).
- [Android kernel: userspace wakelock interface](https://android.googlesource.com/kernel/common/+/refs/heads/android-mainline/kernel/power/wakelock.c).
- [Additional model-specific rooting experience by imSp4rky](https://gist.github.com/imSp4rky/75ca403530780feeb3182d5d269ee421). The command sequence in this README was also checked against our own log; additional claims in that guide about DRM, OTA, or hardware recovery are not presented here as our own test results.

## License and downloads

This project is distributed under GPL-3.0; see LICENSE and THIRD_PARTY_NOTICES.md. Download the installation ZIP from Releases. GitHub's automatic source archives are not installable Magisk ZIPs. This GitHub package includes license and attribution files, so its checksum differs from the earlier sharing bundle; runtime scripts are unchanged.

## Support this project

If this module helped you, you can optionally [support the project via PayPal](https://www.paypal.com/donate/?hosted_button_id=3989J24TFEK9Y). Any amount is appreciated. The module and guide remain free for everyone; donations are never required.
