ASM = nasm
CC = gcc
MKISOFS = mkisofs
PYTHON = python
SRC_DIR = src
BUILD_DIR = build

all: $(BUILD_DIR)/ultraos.iso $(BUILD_DIR)/ultraos-live.iso

# ----------------------------
# Installer ISO
# ----------------------------
$(BUILD_DIR)/ultraos.iso: $(BUILD_DIR)/ultraos-installer.img
	@if not exist $(BUILD_DIR)\iso mkdir $(BUILD_DIR)\iso
	@echo Creating Installer ISO...
	@copy /b $(BUILD_DIR)\ultraos-installer.img $(BUILD_DIR)\iso\boot.img >nul
	$(MKISOFS) -no-emul-boot -b boot.img -o $(BUILD_DIR)\ultraos.iso $(BUILD_DIR)\iso

$(BUILD_DIR)/ultraos-installer.img: $(BUILD_DIR)/boot.bin $(BUILD_DIR)/switcher.bin $(BUILD_DIR)/installer.bin $(BUILD_DIR)/ui.bin
	@if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)
	@echo Creating installer image with proper sector alignment...
	$(PYTHON) build_disk.py installer

# ----------------------------
# Live ISO (full OS, no installer)
# ----------------------------
$(BUILD_DIR)/ultraos-live.iso: $(BUILD_DIR)/ultraos-live.img
	@if not exist $(BUILD_DIR)\live mkdir $(BUILD_DIR)\live
	@echo Creating Live ISO...
	@copy /b $(BUILD_DIR)\ultraos-live.img $(BUILD_DIR)\live\boot.img >nul
	$(MKISOFS) -no-emul-boot -b boot.img -o $(BUILD_DIR)\ultraos-live.iso $(BUILD_DIR)\live

$(BUILD_DIR)/ultraos-live.img: $(BUILD_DIR)/boot.bin $(BUILD_DIR)/switcher.bin $(BUILD_DIR)/ui.bin
	@if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)
	@echo Creating live image with proper sector alignment...
	$(PYTHON) build_disk.py live

# ----------------------------
# Individual binaries
# ----------------------------
$(BUILD_DIR)/boot.bin: $(SRC_DIR)/main.asm
	@if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)
	$(ASM) $(SRC_DIR)/main.asm -f bin -o $(BUILD_DIR)\boot.bin

$(BUILD_DIR)/installer.bin: $(SRC_DIR)/installer.asm
	@if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)
	$(ASM) $(SRC_DIR)/installer.asm -f bin -o $(BUILD_DIR)\installer.bin

$(BUILD_DIR)/switcher.bin: $(SRC_DIR)/switcher.asm
	@if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)
	$(ASM) $(SRC_DIR)/switcher.asm -f bin -o $(BUILD_DIR)\switcher.bin

$(BUILD_DIR)/ui.bin: $(SRC_DIR)/ui.asm
	@if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)
	@echo Assembling UI...
	$(ASM) $(SRC_DIR)/ui.asm -f bin -o $(BUILD_DIR)\ui.bin

# ----------------------------
# Quick test image
# ----------------------------
$(BUILD_DIR)/test.img: $(BUILD_DIR)/boot.bin $(BUILD_DIR)/switcher.bin $(BUILD_DIR)/ui.bin
	$(PYTHON) build_disk.py live
	@copy /b $(BUILD_DIR)\ultraos-live.img $(BUILD_DIR)\test.img > nul

# ----------------------------
# QEMU testing
# ----------------------------
test-iso: $(BUILD_DIR)/ultraos.iso
	qemu-system-x86_64 -cdrom $(BUILD_DIR)\ultraos.iso -drive file=disk.qcow2,format=qcow2 -m 512M -boot d

test-installer: $(BUILD_DIR)/ultraos-installer.img
	qemu-system-x86_64 -drive file=$(BUILD_DIR)\ultraos-installer.img,format=raw -drive file=disk.qcow2,format=qcow2 -m 512M

test-live: $(BUILD_DIR)/ultraos-live.img
	qemu-system-x86_64 -drive file=$(BUILD_DIR)\ultraos-live.img,format=raw -m 512M

test-os: $(BUILD_DIR)/test.img
	qemu-system-x86_64 -drive file=$(BUILD_DIR)\test.img,format=raw -drive file=disk.qcow2,format=qcow2 -m 512M

# ----------------------------
# Clean
# ----------------------------
clean:
	if exist $(BUILD_DIR) rd /S /Q $(BUILD_DIR)

.PHONY: clean all test-iso test-installer test-live test-os