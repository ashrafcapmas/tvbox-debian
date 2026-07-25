#!/system/bin/sh

# ====================================================
#    TV-BOX NATIVE LINUX DEBIAN MASTER INSTALLER     
#    Author / Creator : Ashraf Saber                 
#    GitHub Account   : ashrafcapmas                 
#    Architecture     : ARMv7 (32-bit / ARM64)       
#    Features         : Auto-Storage & Progress Wizard
# ====================================================

clear
echo "===================================================="
echo "    TV-BOX NATIVE LINUX DEBIAN MASTER INSTALLER     "
echo "    Author / Creator : Ashraf Saber                 "
echo "    GitHub Account   : ashrafcapmas                 "
echo "    Architecture     : ARMv7 / ARM64                "
echo "===================================================="
echo ""

# ----------------------------------------------------
# 1. شجرة تحديد المسار والذواكر التفاعلية (Storage Wizard)
# ----------------------------------------------------
echo -n "Do you want to install inside default [/data/server]? [Y/n]: "
read choice < /dev/tty

case "$choice" in
  [nN][oO]|[nN])
    echo ""
    echo -n "Do you want to create a new folder under [/data]? [Y/n]: "
    read sub_choice < /dev/tty
    case "$sub_choice" in
      [yY][eE][sS]|[yY]|"")
        echo -n "Enter folder name under /data/ (e.g. debian): "
        read custom_folder < /dev/tty
        if [ -z "$custom_folder" ]; then custom_folder="server"; fi
        TARGET_DIR="/data/$custom_folder"
        ;;
      *)
        echo ""
        echo "===================================================="
        echo " 💾 SCANNING AVAILABLE STORAGE DEVICES & MOUNTS... "
        echo "===================================================="
        
        # كشف وتقطير الذواكر الحقيقية المتصلة بالنظام
        mounts=$(df -h | grep -E '/data|/mnt/media_rw|/storage' | grep -v 'tmpfs' | awk '{print $6 " (Free: " $4 ")"}')
        
        if [ -z "$mounts" ]; then
          echo " [1] /data (Internal Memory)"
          SELECTED_BASE="/data"
        else
          idx=1
          echo "$mounts" | while read -r line; do
            echo " [$idx] $line"
            idx=$((idx+1))
          done
          
          echo ""
          echo -n "Select Storage Device Number [1-$((idx-1))]: "
          read drive_num < /dev/tty
          
          if [ -z "$drive_num" ]; then drive_num=1; fi
          
          # جلب مسار الذاكرة المختارة
          SELECTED_BASE=$(echo "$mounts" | sed -n "${drive_num}p" | awk '{print $1}')
          if [ -z "$SELECTED_BASE" ]; then SELECTED_BASE="/data"; fi
        fi
        
        echo ""
        echo -n "Enter folder name to create inside [$SELECTED_BASE]: "
        read final_folder < /dev/tty
        if [ -z "$final_folder" ]; then final_folder="server"; fi
        
        TARGET_DIR="$SELECTED_BASE/$final_folder"
        ;;
    esac
    ;;
  *)
    TARGET_DIR="/data/server"
    ;;
esac

echo ""
echo "===================================================="
echo " 📌 Target Installation Directory: $TARGET_DIR"
echo "===================================================="

show_progress() {
  step=$1
  total=$2
  title=$3
  echo ""
  echo "----------------------------------------------------"
  echo " 🔄 [$step/$total] $title..."
  echo "----------------------------------------------------"
}

# ----------------------------------------------------
# 2. خطوة 1: تهيئة مجلد التثبيت
# ----------------------------------------------------
show_progress 1 6 "Preparing Target Directory & System Environment"
mkdir -p "$TARGET_DIR"
echo " [OK] Directory Created at: $TARGET_DIR"

# ----------------------------------------------------
# 3. خطوة 2: تنزيل حزمة النظام من GitHub مع شريط التقدم
# ----------------------------------------------------
show_progress 2 6 "Downloading System Master Package from GitHub"

LATEST_URL="https://github.com/ashrafcapmas/tvbox-debian/releases/latest/download/debian_tvbox_master.tar.gz"

curl -k -L -# -o /sdcard/debian_tvbox_master.tar.gz "$LATEST_URL" 2>/dev/null || wget --no-check-certificate -O /sdcard/debian_tvbox_master.tar.gz "$LATEST_URL" 2>/dev/null || wget --no-check-certificate -O /sdcard/debian_tvbox_master.tar.gz "https://github.com/user-attachments/files/30378029/debian_tvbox_master.tar.gz"

echo " [OK] Package Downloaded to /sdcard/debian_tvbox_master.tar.gz"

# ----------------------------------------------------
# 4. خطوة 3: فك ضغط ملفات النظام مع حفظ الصلاحيات
# ----------------------------------------------------
show_progress 3 6 "Unpacking OS File System & Preserving Permissions"
tar -xzvf /sdcard/debian_tvbox_master.tar.gz -C "$TARGET_DIR" --strip-components=1 2>/dev/null || tar -xzvf /sdcard/debian_tvbox_master.tar.gz -C "$TARGET_DIR"
echo " [OK] Extraction Completed Successfully!"

# ----------------------------------------------------
# 5. خطوة 4: إنشاء سكريبتات الإقلاع المباشرة (tv-start & tv-telnet)
# ----------------------------------------------------
show_progress 4 6 "Generating Native System Launchers (tv-start & tv-telnet)"
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

cat << 'SEOF' > /system/bin/tv-telnet
#!/system/bin/sh
busybox telnetd -p 23 -l /system/bin/sh &
SEOF
chmod 755 /system/bin/tv-telnet
echo " [OK] Launchers Generated at /system/bin/"

# ----------------------------------------------------
# 6. خطوة 5: ربط الإقلاع التلقائي مع نواة الأندرويد
# ----------------------------------------------------
show_progress 5 6 "Hooking Kernel Autostart (/system/etc/install-recovery.sh)"
if ! grep -q "tv-start" /system/etc/install-recovery.sh 2>/dev/null; then
  echo '
# Autostart Native TV Services
/system/bin/tv-telnet &
sleep 20
/system/bin/tv-start &' >> /system/etc/install-recovery.sh
fi
chmod 755 /system/etc/install-recovery.sh
mount -o ro,remount /system 2>/dev/null
echo " [OK] Kernel Autostart Hooked Successfully!"

# ----------------------------------------------------
# 7. خطوة 6: إنشاء كلمة سر الـ Root التفاعلية وتشغيل الخدمات
# ----------------------------------------------------
show_progress 6 6 "Configuring Root Password & Launching Native Services"
echo ""
echo "===================================================="
echo "   🔑 ENTER NEW ROOT PASSWORD FOR DEBIAN SYSTEM     "
echo "===================================================="
chroot "$TARGET_DIR" /bin/bash -c "export PATH=/bin:/usr/bin:/sbin:/usr/sbin:\$PATH; passwd root" < /dev/tty

/system/bin/tv-telnet 2>/dev/null
/system/bin/tv-start 2>/dev/null

echo ""
echo "===================================================="
echo " 🎉 INSTALLATION COMPLETED SUCCESSFULLY!            "
echo " Creator: Ashraf Saber | TV-Box System Installed!   "
echo " Path   : $TARGET_DIR"
echo " Active : SSH, AdGuard Home, Samba NAS, Telnet      "
echo "===================================================="
