#!/sbin/sh
# Laksanasoft External & Internal Media Boot Engine
# Samsung Galaxy S10+ (beyond2lte) Custom Boot System

export PATH=/sbin:/system/bin:/system/xbin:$PATH

echo "========================================================"
echo "    LAKSANASOFT LINUX BOOT ENGINE (INTERNAL & EXTERNAL) "
echo "========================================================"

MOUNT_POINT="/mnt/linux_rootfs"
mkdir -p $MOUNT_POINT

TARGET_DEV=""
DEV_TYPE=""

# 1. Check Internal Storage rootfs folder (/data/media/0/rootfs or /sdcard/rootfs)
if [ -d "/sdcard/rootfs" ] || [ -d "/data/media/0/rootfs" ] || [ -d "/data/rootfs" ]; then
    ROOTFS="/sdcard/rootfs"
    [ -d "/data/media/0/rootfs" ] && ROOTFS="/data/media/0/rootfs"
    [ -d "/data/rootfs" ] && ROOTFS="/data/rootfs"
    echo "[+] Found Internal Storage Linux RootFS at: $ROOTFS"
    echo "[+] Binding virtual filesystems (/dev, /proc, /sys)..."
    mount -o bind /dev $ROOTFS/dev 2>/dev/null || true
    mount -t proc proc $ROOTFS/proc 2>/dev/null || true
    mount -t sysfs sys $ROOTFS/sys 2>/dev/null || true
    mount -t devpts devpts $ROOTFS/dev/pts 2>/dev/null || true
    echo "[+] Booting Native Linux from Internal Storage /sdcard/rootfs..."
    chroot $ROOTFS /bin/bash -c "export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; [ -f /sbin/init ] && exec /sbin/init || exec /bin/bash"
    exit 0
fi

# 2. Check USB OTG Flash Drive (/dev/block/sda1 or sdb1)
if [ -b "/dev/block/sda1" ]; then
    TARGET_DEV="/dev/block/sda1"
    DEV_TYPE="USB OTG Flash Drive"
elif [ -b "/dev/block/sdb1" ]; then
    TARGET_DEV="/dev/block/sdb1"
    DEV_TYPE="USB OTG Flash Drive"
# 3. Check MicroSD Card (/dev/block/mmcblk0p1 or mmcblk0p2)
elif [ -b "/dev/block/mmcblk0p2" ]; then
    TARGET_DEV="/dev/block/mmcblk0p2"
    DEV_TYPE="MicroSD Card (EXT4)"
elif [ -b "/dev/block/mmcblk0p1" ]; then
    TARGET_DEV="/dev/block/mmcblk0p1"
    DEV_TYPE="MicroSD Card"
fi

if [ -z "$TARGET_DEV" ]; then
    echo "[-] Error: No Internal Storage /sdcard/rootfs, MicroSD, or USB OTG detected!"
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
elif [ -d "$MOUNT_POINT/rootfs" ] || [ -d "$MOUNT_POINT/ubuntu" ] || [ -d "$MOUNT_POINT/kali" ]; then
    ROOTFS=""
    [ -d "$MOUNT_POINT/rootfs" ] && ROOTFS="$MOUNT_POINT/rootfs"
    [ -d "$MOUNT_POINT/ubuntu" ] && ROOTFS="$MOUNT_POINT/ubuntu"
    [ -d "$MOUNT_POINT/kali" ] && ROOTFS="$MOUNT_POINT/kali"
    
    echo "[+] Found External Linux Live RootFS at $ROOTFS"
    echo "[+] Mounting chroot system..."
    mount -o bind /dev $ROOTFS/dev 2>/dev/null || true
    mount -t proc proc $ROOTFS/proc 2>/dev/null || true
    mount -t sysfs sys $ROOTFS/sys 2>/dev/null || true
    echo "[+] Entering Linux Live environment..."
    chroot $ROOTFS /bin/bash
else
    echo "[!] No bootable boot.img or Linux rootfs directory found."
    echo "[!] Place rootfs in Internal Storage (/sdcard/rootfs) or USB/MicroSD (/rootfs)."
fi
