#!/sbin/sh
# Laksanasoft NetHunter Recovery Rescue & Utility Script
export PATH=/sbin:/system/bin:/system/xbin:$PATH

echo "========================================================"
echo "    LAKSANASOFT NETHUNTER RECOVERY RESCUE TOOLKIT"
echo "========================================================"

mount_data() {
  echo "[+] Mounting /data..."
  [ -d /data ] || mkdir -p /data
  mount -t ext4 -o rw /dev/block/by-name/userdata /data 2>/dev/null || mount /data 2>/dev/null || true
}

mount_nethunter() {
  mount_data
  echo "[+] Mounting NetHunter Kali Chroot..."
  if [ -d /data/local/nhsystem/kali-arm64 ]; then
    mount -o bind /dev /data/local/nhsystem/kali-arm64/dev
    mount -t proc proc /data/local/nhsystem/kali-arm64/proc
    mount -t sysfs sys /data/local/nhsystem/kali-arm64/sys
    echo "[+] NetHunter Chroot mounted successfully at /data/local/nhsystem/kali-arm64"
  else
    echo "[-] NetHunter Chroot not found at /data/local/nhsystem/kali-arm64"
  fi
}

case "$1" in
  chroot)
    mount_nethunter
    chroot /data/local/nhsystem/kali-arm64 /bin/bash
    ;;
  mount)
    mount_nethunter
    ;;
  *)
    echo "Usage: nh-rescue {mount|chroot}"
    ;;
esac
