# Twilight Standby Discoverability v1.1

[![Donate with PayPal](https://img.shields.io/badge/Donate-PayPal-0070BA?style=flat&logo=paypal)](https://www.paypal.com/donate/?hosted_button_id=3989J24TFEK9Y) [![Donate with Revolut](https://img.shields.io/badge/Donate-Revolut-191C1F?style=flat&logo=revolut)](https://revolut.me/j_rouwhorst)

A Magisk module that holds one kernel wakelock to keep the tested Xiaomi TV Box S 3rd Gen reachable during standby over Wi-Fi or USB Ethernet.

- Tested firmware: V816.0.11.0.UZFAABX, Android 14; Magisk 30.7.
- Root is required; standby power consumption increases.
- No framework, property, CEC, or Doze settings are changed by the module.
- Turn USB debugging **off** when using USB Ethernet on the tested box; turn it **on** for USB ADB.
- Version 1.1 renames the v1.0 module; runtime scripts are unchanged. The internal ID stays `twilight_ethernet_standby` for upgrades.
- The GitHub package adds license and attribution files. Installation of this repackaged ZIP has not been separately tested on hardware.

Download the module ZIP attached to this release. GitHub's automatic Source code archives are not Magisk installation ZIPs. Read README.md for installation, verification, separate rooting instructions, known limitations, and removal.
