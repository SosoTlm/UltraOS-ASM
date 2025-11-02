# UltraOS

Welcome girls & boys to the... **UltraOS Guide !**

Here you'll see how UltraOS works & is made!

Let's begin!

## 1. Downloading
You maybe are- um you are confused 99% yea about wich files to download, right? (say yes)

You came to the right place!

So heres a little breakdown.

| File | Purpose | Boot Mode |
|------|----------|-----------|
| `ultraos.iso` | Boots the entire operating system | Legacy/CSM |
| `ultraos-live.iso` | Boots the OS in live mode for testing | Legacy/CSM |
| `ultraos.img` | Boots the entire operating system | Legacy/CSM |
| `ultraos-live.img` | Boots the OS in live mode for testing | Legacy/CSM |

## 2. Installation
> [ATTENTION]: Installation section has been wipped due to the ultraos.iso/ultraos.img corrupting your data! This is highly dangerous and i'm working on it!

## 3. Requirements
| Minimal | Recommended |
|------|----------|
| 64bit 252MHz CPU | 64bit 400MHz CPU |
| 10MB of Memory | 40MB of Memory |
| 500MB of Disk Space | 1GB of Disk Space |
| Default VGA Driver | Dedicated GPU/Integrated GPU |

About the space part it's because the more you allocate, the faster it boots

## 4. About UltraOS
UltraOS first versions were made in python wich are now discontinued and still available on SosoTlm/ultra-os

This UltraOS is made in 100% ASM and is bootable on real hardware wich is great because making a real operating system was my dream!

``main.asm`` is considered the kernel, it will handles the tasks of asking the CPU to run this, that etc...

``switcher.asm`` is considered as the bootloader, it will handle tasks such as Rebooting the device and starting the UI.

``ui.asm`` is the new version of ``ui.c`` as it's easier to make (beacause i don't wanna make whole C file wich is 300 lines long) and faster to boot!

``pad1440.bin`` is the deprecated custom padder to force the .img's to be 1.4MB so it fits on a floppy disk. Useless but i keep it in case i need it.

``ui.c`` is the deprecated UltraOS's user interface. It's not so useless for future release like if i manage to make a sleek interface.

``installer.asm`` ah yes! The data corrupter! it's in work because it corrupts your data after selecting the disk of your choice.

``disk.qcow2`` i never deleted this because i need it to test if the installer works and when it works i'll reset it's data so you are forcd to install it manually with qemu :D!

``ui_linker.ld`` is just to say to switcher.asm to boot the ui.bin instead of ui.o.

``Makefile`` you tought you find a secret file but no, it's just the compiler.

``build_disk.py`` is a script for me to make the live iso and img because makefile hated me :,).

Next: [UltraOS - Live ISO/IMG](/docs/LiveISO.md)
