#!/bin/bash
set -e

echo "[+] 1. Setting up vendor/omni compatibility layer..."
cd ~/twrp
mkdir -p vendor/omni/config
touch vendor/omni/config/common.mk
if [ -d vendor/twrp/config ]; then
  cp -rf vendor/twrp/config/* vendor/omni/config/ 2>/dev/null || true
fi

echo "[+] 2. Configuring Samsung S10+ device tree..."
cd device/samsung/beyond2lte

if [ -f omni_beyond2lte.mk ]; then
  cp omni_beyond2lte.mk twrp_beyond2lte.mk
  sed -i 's/vendor\/omni/vendor\/twrp/g' twrp_beyond2lte.mk
  sed -i 's/omni_beyond2lte/twrp_beyond2lte/g' twrp_beyond2lte.mk
fi

cat << 'EOF' > AndroidProducts.mk
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/twrp_beyond2lte.mk \
    $(LOCAL_DIR)/omni_beyond2lte.mk

COMMON_LUNCH_CHOICES := \
    twrp_beyond2lte-eng \
    twrp_beyond2lte-userdebug \
    omni_beyond2lte-eng
EOF

# Hardware & Driver Partition Configurations (67,633,152 Bytes Exact Hardware Match)
echo "BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67633152" >> BoardConfig.mk
echo "BOARD_HAS_NO_REAL_SDCARD := false" >> BoardConfig.mk
echo "RECOVERY_SDCARD_ON_DATA := false" >> BoardConfig.mk
echo "TW_LOAD_VENDOR_MODULES := true" >> BoardConfig.mk
echo "TW_USE_EXTERNAL_STORAGE := true" >> BoardConfig.mk
echo "TW_HAS_MTP := true" >> BoardConfig.mk

# Feature flags
echo "TW_INCLUDE_CRYPTO := true" >> BoardConfig.mk
echo "TW_INCLUDE_NTFS_3G := true" >> BoardConfig.mk
echo "TW_EXCLUDE_DEFAULT_USB_INIT := false" >> BoardConfig.mk
echo "TW_ALLOW_EXPOSED_USE_GAPPS := true" >> BoardConfig.mk
echo "TW_BRIGHTNESS_PATH := \"/sys/class/backlight/panel/brightness\"" >> BoardConfig.mk
echo "TW_MAX_BRIGHTNESS := 255" >> BoardConfig.mk
echo "TW_DEFAULT_BRIGHTNESS := 150" >> BoardConfig.mk
echo "TW_EXTRA_LANGUAGES := true" >> BoardConfig.mk
echo "TW_INCLUDE_RESETPROP := true" >> BoardConfig.mk
echo "TW_INCLUDE_REPACKBOOT := true" >> BoardConfig.mk
echo "TW_ALWAYS_ALLOW_UNRESTRICTED_USB := true" >> BoardConfig.mk
echo "TW_FORCE_CPUINFO := true" >> BoardConfig.mk
echo "TW_INCLUDE_FASTBOOTD := true" >> BoardConfig.mk
echo "BUILD_FASTBOOTD := true" >> BoardConfig.mk
echo "TARGET_RECOVERY_DEVICE_MODULES += fastbootd" >> BoardConfig.mk

echo "[+] 3. Injecting Auto-Boot Detect Hook & NetHunter Rescue Scripts..."
mkdir -p recovery/root/sbin
cp $GITHUB_WORKSPACE/scripts/nethunter_recovery_rescue.sh recovery/root/sbin/nh-rescue
cp $GITHUB_WORKSPACE/scripts/extboot.sh recovery/root/sbin/extboot
cp $GITHUB_WORKSPACE/scripts/extboot.sh recovery/root/sbin/sdboot
chmod +x recovery/root/sbin/nh-rescue recovery/root/sbin/extboot recovery/root/sbin/sdboot

# Inject Auto-Detect SD/USB Boot service into recovery init.rc
mkdir -p recovery/root/etc
cat << 'EOF' > recovery/root/etc/init.recovery.sdboot.rc
on boot
    exec /sbin/sdboot --auto-detect
EOF
echo "import /etc/init.recovery.sdboot.rc" >> recovery/root/init.rc

echo "[+] 4. Executing Custom Recovery Build..."
cd ~/twrp
export ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch twrp_beyond2lte-eng || lunch twrp_beyond2lte-userdebug || lunch omni_beyond2lte-eng
mka recoveryimage -j$(nproc --all)
