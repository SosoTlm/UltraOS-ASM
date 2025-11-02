#!/usr/bin/env python3
"""
UltraOS Disk Image Builder
Creates properly aligned disk images with sector boundaries
"""

import sys
import os

def pad_to_sector(data, sector_size=512):
    """Pad data to next sector boundary"""
    remainder = len(data) % sector_size
    if remainder != 0:
        padding = sector_size - remainder
        data += b'\x00' * padding
    return data

def write_at_sector(disk, data, sector_num, sector_size=512):
    """Write data at a specific sector"""
    offset = sector_num * sector_size
    # Ensure disk is large enough
    if len(disk) < offset + len(data):
        disk += b'\x00' * (offset + len(data) - len(disk))
    # Write data
    disk = disk[:offset] + data + disk[offset + len(data):]
    return disk

def build_installer_image(boot_file, switcher_file, installer_file, ui_file, output_file):
    """Build installer disk image"""
    print("Building installer image...")
    
    # Create empty 1.44MB disk
    disk = bytearray(1440 * 1024)  # 1.44 MB floppy size
    
    # Read binaries
    try:
        with open(boot_file, 'rb') as f:
            boot = f.read()
        with open(switcher_file, 'rb') as f:
            switcher = f.read()
        with open(installer_file, 'rb') as f:
            installer = f.read()
        with open(ui_file, 'rb') as f:
            ui = f.read()
    except FileNotFoundError as e:
        print(f"Error: {e}")
        return False
    
    # Verify sizes
    print(f"  Boot:      {len(boot)} bytes (sector 0)")
    print(f"  Switcher:  {len(switcher)} bytes (sector 1-4)")
    print(f"  Installer: {len(installer)} bytes (sector 5-8)")
    print(f"  UI:        {len(ui)} bytes (sector 9+)")
    
    if len(boot) > 512:
        print(f"ERROR: Bootloader too large ({len(boot)} bytes, max 512)")
        return False
    if len(switcher) > 2048:
        print(f"ERROR: Switcher too large ({len(switcher)} bytes, max 2048)")
        return False
    if len(installer) > 2048:
        print(f"ERROR: Installer too large ({len(installer)} bytes, max 2048)")
        return False
    
    # Write components at correct sectors
    disk = write_at_sector(disk, boot, 0)         # Sector 0 (bootloader)
    disk = write_at_sector(disk, switcher, 1)     # Sector 1-4 (switcher)
    disk = write_at_sector(disk, installer, 5)    # Sector 5-8 (installer)
    disk = write_at_sector(disk, ui, 9)           # Sector 9+ (UI)
    
    # Write to file
    with open(output_file, 'wb') as f:
        f.write(disk)
    
    print(f"✓ Created {output_file} ({len(disk)} bytes)")
    return True

def build_live_image(boot_file, switcher_file, ui_file, output_file):
    """Build live disk image (no installer)"""
    print("Building live image...")
    
    # Create empty 1.44MB disk
    disk = bytearray(1440 * 1024)
    
    # Read binaries
    try:
        with open(boot_file, 'rb') as f:
            boot = f.read()
        with open(switcher_file, 'rb') as f:
            switcher = f.read()
        with open(ui_file, 'rb') as f:
            ui = f.read()
    except FileNotFoundError as e:
        print(f"Error: {e}")
        return False
    
    # Verify sizes
    print(f"  Boot:     {len(boot)} bytes (sector 0)")
    print(f"  Switcher: {len(switcher)} bytes (sector 1-4)")
    print(f"  UI:       {len(ui)} bytes (sector 9+)")
    
    if len(boot) > 512:
        print(f"ERROR: Bootloader too large ({len(boot)} bytes, max 512)")
        return False
    if len(switcher) > 2048:
        print(f"ERROR: Switcher too large ({len(switcher)} bytes, max 2048)")
        return False
    
    # Write components at correct sectors
    disk = write_at_sector(disk, boot, 0)      # Sector 0 (bootloader)
    disk = write_at_sector(disk, switcher, 1)  # Sector 1-4 (switcher)
    disk = write_at_sector(disk, ui, 9)        # Sector 9+ (UI)
    
    # Write to file
    with open(output_file, 'wb') as f:
        f.write(disk)
    
    print(f"✓ Created {output_file} ({len(disk)} bytes)")
    return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python build_disk.py installer")
        print("  python build_disk.py live")
        sys.exit(1)
    
    mode = sys.argv[1]
    
    if mode == "installer":
        success = build_installer_image(
            "build/boot.bin",
            "build/switcher.bin",
            "build/installer.bin",
            "build/ui.bin",
            "build/ultraos-installer.img"
        )
    elif mode == "live":
        success = build_live_image(
            "build/boot.bin",
            "build/switcher.bin",
            "build/ui.bin",
            "build/ultraos-live.img"
        )
    else:
        print(f"Unknown mode: {mode}")
        success = False
    
    sys.exit(0 if success else 1)