# UltraOS - Live ISO/IMG

---
>[WARNING]: if you haven't seen how the OS works first, please go to [UltraOS - Start](/docs/Start.md)

---

You may wonder now "**__I want to try it in live first!__**" but you don't see live option? It's totally ***__normal__***! Installer and Live files come seperate as we boot on the parent device for live and on the target device for installer!

Also the installer is kinda buggy right now and i'm finding a way to prevent it from corrupting data...

## 1. Booting (in QEMU)

Yea you're right to try it on QEMU first but anyways.

Go to the directory where your ``ultraos-live.img`` is and run this command:
```
qemu-system-x86_64 -drive file=ultraos-live.img,format=raw -m 512M
```
You can also change memory allocation to min 10M (``-m 10M``) for the UI to actualy show up otherwise you'll see a triple fault and it'll straight crash or straight reboot.

Yea the UI takes 5MB of Memory. But only ui.c but even with ui.asm just keep it 10M or if you wanna be safe do 50M.

## 2. Booting in REAL Hardware
Now you look confident huh?

Yeah so now screw Rufus and BalenaEtcher and use Ventoy MBR (latest please) and disable Secure Boot support as we are gonna boot your usb in Legacy Mode (if supported)!.

Firstly grab ``ultraos-live.iso`` from the files.

Access to your device's BIOS and spamming the key Del or F2/Fn+F2 after pressing the power button and wait t'ill an UEFI or a BIOS screen appears.

Go to Boot and Find Boot Mode.
If you see CSM as an option but not Legacy then choose CSM (it's- it's the same thing, trust) and then plug your usb, go to your Boot Menu (usually F12/F1) and choose your usb device.

Next you'll see a buggy ventoy screen but that's not a problem.

Choose ``ultraos-live.iso`` press enter and choose Normal Mode press enter.

***__Here you go! You have booten up the live iso!__***

Next: [UltraOS - Using Open Sourced Code](/docs/UOSCode.md)