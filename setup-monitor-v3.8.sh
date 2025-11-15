#!/data/data/com.termux/files/usr/bin/bash
# === JR x Top: Lao HTTPS Block Monitor — Setup v3.8 ===
# ✔ ล้างไฟล์เก่า / cron เก่า
# ✔ ดาวน์โหลด lao-monitor.sh ตัวล่าสุด
# ✔ ตั้ง cron ใหม่
# ✔ พร้อมใช้งานทันที

echo "🚀 กำลังติดตั้ง Lao HTTPS Monitor v3.8..."

# ------------------------------------------------
# CONFIG
# ------------------------------------------------
SCRIPT_URL="https://raw.githubusercontent.com/topfrom1982-wq/setup-scripts/main/lao-monitor.sh"
DOMAIN_URL="https://raw.githubusercontent.com/topfrom1982-wq/domains/main/domains.txt"

SCRIPT_PATH="$HOME/lao-monitor.sh"
LOG="$HOME/lao-monitor.log"
DOMAIN_FILE="$HOME/domains.txt"

CRON_FILE="$PREFIX/var/spool/cron/crontabs/$(whoami)"

# ------------------------------------------------
# ล้างของเก่าก่อนติดตั้ง
# ------------------------------------------------
echo "🧹 ล้างไฟล์เก่า..."
rm -f "$SCRIPT_PATH" "$LOG" "$DOMAIN_FILE" "$HOME/lao-monitor-new.sh" 2>/dev/null

echo "🧹 ล้าง cron เก่า..."
sed -i '/lao-monitor.sh/d' "$CRON_FILE" 2>/dev/null

# ------------------------------------------------
# ติดตั้ง package ที่จำเป็น
# ------------------------------------------------
echo "📦 ติดตั้งแพ็กเกจที่จำเป็น..."
pkg update -y > /dev/null 2>&1
pkg install -y curl jq cronie termux-api > /dev/null 2>&1

# ------------------------------------------------
# ดาวน์โหลดไฟล์ main script
# ------------------------------------------------
echo "⬇️ ดาวน์โหลด lao-monitor.sh..."
curl -s -o "$SCRIPT_PATH" "$SCRIPT_URL"
chmod +x "$SCRIPT_PATH"

# ดาวน์โหลด domains ครั้งแรก
echo "⬇️ ดาวน์โหลด domains.txt..."
curl -s -o "$DOMAIN_FILE" "$DOMAIN_URL"

# ------------------------------------------------
# ตั้ง cron ใหม่
# ------------------------------------------------
echo "📅 ตั้ง cron ให้รันทุก 10 นาที..."
mkdir -p $(dirname "$CRON_FILE")
sed -i '/lao-monitor.sh/d' "$CRON_FILE" 2>/dev/null
echo "*/10 * * * * bash $SCRIPT_PATH" >> "$CRON_FILE"

# เริ่ม cron
crond
termux-wake-lock

# ------------------------------------------------
# เริ่มตรวจรอบแรก
# ------------------------------------------------
echo "▶️ เริ่มรอบแรก..."
bash "$SCRIPT_PATH"

echo "✅ ติดตั้งสำเร็จเรียบร้อยแล้ว v3.8"
echo "📜 Log: $LOG"
echo "🌍 Domain list: $DOMAIN_FILE"
echo "🕑 Cron: ทุก 10 นาที"
