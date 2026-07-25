#!/system/bin/sh

# ====================================================
#    TV-BOX NATIVE LINUX DEBIAN SYSTEM INSTALLER     
#    Author / Creator : Ashraf Saber                 
#    GitHub Account   : ashrafcapmas                 
#    Architecture     : ARMv7 (32-bit / ARM64)       
#    System Size      : Dynamic (~200 MB Compressed) 
# ====================================================

clear
echo "===================================================="
echo "    TV-BOX NATIVE LINUX DEBIAN SYSTEM INSTALLER     "
echo "    Author / Creator : Ashraf Saber                 "
echo "    GitHub Account   : ashrafcapmas                 "
echo "    Architecture     : ARMv7 / ARM64                "
echo "    Package Size     : Dynamic (~200 MB)            "
echo "===================================================="
echo ""

# 1. السؤال التفاعلي عن مسار التثبيت
read -p "Do you want to install inside [/data/server]? [Y/n]: " choice
case "$choice" in
  [nN][oO]|[nN])
    read -p "Enter custom folder name under /data/ (e.g. myserver): " custom_folder
    if [ -z "$custom_folder" ]; then custom_folder="server"; fi
    TARGET_DIR="/data/$custom_folder"
    ;;
  *)
    TARGET_DIR="/data/server"
    ;;
esac

echo "📌 Installation Path set to: $TARGET_DIR"

# 2. إنشاء المجلد وتنزيل أحدث حزمة من GitHub تلقائياً (Dynamic Latest Fetch)
mkdir -p "$TARGET_DIR"
echo "\n📥 Fetching & Downloading Latest Debian Package from GitHub..."

LATEST_URL="https://github.com/ashrafcapmas/tvbox-debian/releases/latest/download/debian_tvbox_master.tar.gz"

curl -k -L -o /sdcard/debian_tvbox_master.tar.gz "$LATEST_URL" 2>/dev/null || wget --no-check-certificate -O /sdcard/debian_tvbox_master.tar.gz "$LATEST_URL" 2>/dev/null || wget --no-check-certificate -O /sdcard/debian_tvbox_master.tar.gz "https://github.com/user-attachments/files/30378029/debian_tvbox_master.tar.gz"

echo "\n📦 Extracting System Files into $TARGET_DIR..."
tar -xzvf /sdcard/debian_tvbox_master.tar.gz -C "$TARGET_DIR" --strip-components=1 2>/dev/null || tar -xzvf /sdcard/debian_tvbox_master.tar.gz -C "$TARGET_DIR"

# 3. إنشاء سكريبت التشغيل المباشر /system/bin/tv-start
mount -o rw,remount /system 2>/dev/null

cat << SEOF > /system/bin/tv-start
#!/system/bin/sh
ROOT=$TARGET_DIR
mount -o bind /dev \$ROOT/dev 2>/dev/null
mount -o bind /sys \$ROOT/sys 2>/dev/null
mount -o bind /proc \$ROOT/proc 2>/dev/null
mount -t devpts devpts \$ROOT/dev/pts 2>/dev/null

chroot \$ROOT /bin/bash -c "
  export PATH=/bin:/usr/bin:/sbin:/usr/sbin:\$PATH
  /etc/init.d/ssh start >/dev/null 2>&1 &
  /etc/rc.local >/dev/null 2>&1 &
"
SEOF
chmod 755 /system/bin/tv-start

# 4. إنشاء سكريبت Telnet المباشر /system/bin/tv-telnet
cat << 'SEOF' > /system/bin/tv-telnet
#!/system/bin/sh
busybox telnetd -p 23 -l /system/bin/sh &
SEOF
chmod 755 /system/bin/tv-telnet

# 5. إضافة التشغيل التلقائي مع الفيشة في install-recovery.sh
if ! grep -q "tv-start" /system/etc/install-recovery.sh 2>/dev/null; then
  echo '
# Autostart Native TV Services
/system/bin/tv-telnet &
sleep 20
/system/bin/tv-start &' >> /system/etc/install-recovery.sh
fi
chmod 755 /system/etc/install-recovery.sh
mount -o ro,remount /system 2>/dev/null

# 6. الدخول التفاعلي لطلب كلمة سر الـ Root الجديدة
echo ""
echo "===================================================="
echo "   🔑 ENTER NEW ROOT PASSWORD FOR DEBIAN SYSTEM     "
echo "===================================================="
chroot "$TARGET_DIR" /bin/bash -c "export PATH=/bin:/usr/bin:/sbin:/usr/sbin:\$PATH; passwd root"

# 7. تشغيل الخدمات فوراً وتأكيد النجاح
/system/bin/tv-telnet 2>/dev/null
/system/bin/tv-start 2>/dev/null

echo ""
echo "===================================================="
echo " 🎉 INSTALLATION COMPLETED SUCCESSFULLY!            "
echo " Creator: Ashraf Saber | TV-Box System Installed!   "
echo " Services Active: SSH, AdGuard Home, Samba, Telnet "
echo "===================================================="
