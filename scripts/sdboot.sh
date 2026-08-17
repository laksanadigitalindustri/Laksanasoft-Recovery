#!/sbin/sh
# Laksanasoft SD-Boot Engine for Samsung Galaxy S10+ (beyond2lte)
# Allows booting Linux ARM64 / Secondary OS directly from MicroSD Card

export PATH=/sbin:/system/bin:/system/xbin:$PATH

echo "========================================================"
echo "    LAKSANASOFT MICROSD BOOT ENGINE (SD-BOOT)"
echo "========================================================"

SD_DEV="/dev/block/mmcblk0p1"
SD_DEV_EXT4="/dev/block/mmcblk0p2"
SD_MOUNT="/external_sd"

mkdir -p $SD_MOUNT

echo "[+] 1. Detecting MicroSD Card..."
if [ -b "$SD_DEV_EXT4" ]; then
    echo "[+] Found Linux EXT4 partition on MicroSD ($SD_DEV_EXT4)"
    mount -t ext4 -o rw $SD_DEV_EXT4 $SD_MOUNT 2>/dev/null || mount $SD_DEV $SD_MOUNT 2>/dev/null
elif [ -b "$SD_DEV" ]; then
    echo "[+] Found MicroSD partition ($SD_DEV)"
    mount -t vfat -o rw $SD_DEV $SD_MOUNT 2>/dev/null || mount -t exfat -o rw $SD_DEV $SD_MOUNT 2>/dev/null || mount $SD_DEV $SD_MOUNT 2>/dev/null
else
    echo "[-] MicroSD Card not detected in mmcblk0!"
    exit 1
fi

echo "[+] MicroSD mounted at $SD_MOUNT"

if [ -f "$SD_MOUNT/boot/boot.img" ]; then
    echo "[+] Found custom boot image at $SD_MOUNT/boot/boot.img"
    echo "[+] Flashing $SD_MOUNT/boot/boot.img to /dev/block/by-name/boot..."
    dd if=$SD_MOUNT/boot/boot.img of=/dev/block/by-name/boot status=progress
    echo "[+] MicroSD Boot Image flashed successfully! Rebooting..."
    reboot
elif [ -d "$SD_MOUNT/ubuntu" ] || [ -d "$SD_MOUNT/kali" ]; then
    echo "[+] Found Standalone Linux RootFS on MicroSD!"
    echo "[+] Preparing chroot environment..."
    ROOTFS=""
    [ -d "$SD_MOUNT/ubuntu" ] && ROOTFS="$SD_MOUNT/ubuntu"
    [ -d "$SD_MOUNT/kali" ] && ROOTFS="$SD_MOUNT/kali"
    
    mount -o bind /dev $ROOTFS/dev
    mount -t proc proc $ROOTFS/proc
    mount -t sysfs sys $ROOTFS/sys
    echo "[+] Entering MicroSD Linux OS..."
    chroot $ROOTFS /bin/bash
else
    echo "[!] No bootable boot.img or Linux rootfs found on MicroSD."
    echo "[!] Place boot.img in MicroSD at: /boot/boot.img"
fi
