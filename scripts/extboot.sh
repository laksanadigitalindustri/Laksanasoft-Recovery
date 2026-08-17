#!/sbin/sh
# Laksanasoft External Media Boot Engine (MicroSD & USB OTG Live Boot)
# Samsung Galaxy S10+ (beyond2lte) Custom Recovery Utility

export PATH=/sbin:/system/bin:/system/xbin:$PATH

echo "========================================================"
echo "    LAKSANASOFT EXTERNAL BOOT ENGINE (MICROSD & USB OTG)"
echo "========================================================"

MOUNT_POINT="/external_sd"
mkdir -p $MOUNT_POINT

TARGET_DEV=""
DEV_TYPE=""

# 1. Check USB OTG Flash Drive (/dev/block/sda1 or sdb1)
if [ -b "/dev/block/sda1" ]; then
    TARGET_DEV="/dev/block/sda1"
    DEV_TYPE="USB OTG Flash Drive"
elif [ -b "/dev/block/sdb1" ]; then
    TARGET_DEV="/dev/block/sdb1"
    DEV_TYPE="USB OTG Flash Drive"
# 2. Check MicroSD Card (/dev/block/mmcblk0p1 or mmcblk0p2)
elif [ -b "/dev/block/mmcblk0p2" ]; then
    TARGET_DEV="/dev/block/mmcblk0p2"
    DEV_TYPE="MicroSD Card (EXT4)"
elif [ -b "/dev/block/mmcblk0p1" ]; then
    TARGET_DEV="/dev/block/mmcblk0p1"
    DEV_TYPE="MicroSD Card"
fi

if [ -z "$TARGET_DEV" ]; then
    echo "[-] Error: No MicroSD Card or USB OTG Flash Drive detected!"
    exit 1
fi

echo "[+] Detected $DEV_TYPE at $TARGET_DEV"
echo "[+] Mounting $TARGET_DEV to $MOUNT_POINT..."

mount -t ext4 -o rw $TARGET_DEV $MOUNT_POINT 2>/dev/null || \
mount -t vfat -o rw $TARGET_DEV $MOUNT_POINT 2>/dev/null || \
mount -t exfat -o rw $TARGET_DEV $MOUNT_POINT 2>/dev/null || \
mount $TARGET_DEV $MOUNT_POINT 2>/dev/null

if [ -f "$MOUNT_POINT/boot/boot.img" ] || [ -f "$MOUNT_POINT/boot.img" ]; then
    BOOT_FILE="$MOUNT_POINT/boot/boot.img"
    [ -f "$MOUNT_POINT/boot.img" ] && BOOT_FILE="$MOUNT_POINT/boot.img"
    echo "[+] Found Linux/OS Boot Image: $BOOT_FILE"
    echo "[+] Flashing $BOOT_FILE to /dev/block/by-name/boot..."
    dd if=$BOOT_FILE of=/dev/block/by-name/boot status=progress
    echo "[+] Boot Image flashed successfully! Rebooting system..."
    reboot
elif [ -d "$MOUNT_POINT/ubuntu" ] || [ -d "$MOUNT_POINT/kali" ] || [ -d "$MOUNT_POINT/arch" ]; then
    ROOTFS=""
    [ -d "$MOUNT_POINT/ubuntu" ] && ROOTFS="$MOUNT_POINT/ubuntu"
    [ -d "$MOUNT_POINT/kali" ] && ROOTFS="$MOUNT_POINT/kali"
    [ -d "$MOUNT_POINT/arch" ] && ROOTFS="$MOUNT_POINT/arch"
    
    echo "[+] Found Linux Live RootFS at $ROOTFS"
    echo "[+] Mounting chroot system..."
    mount -o bind /dev $ROOTFS/dev
    mount -t proc proc $ROOTFS/proc
    mount -t sysfs sys $ROOTFS/sys
    echo "[+] Entering Linux Live environment..."
    chroot $ROOTFS /bin/bash
else
    echo "[!] No bootable boot.img or Linux rootfs directory found on $DEV_TYPE."
    echo "[!] Place boot.img at /boot.img or rootfs folder (/ubuntu, /kali, /arch) on USB/MicroSD."
fi
