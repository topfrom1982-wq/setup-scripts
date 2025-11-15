#!/data/data/com.termux/files/usr/bin/bash
# === JR x Top: Lao HTTPS Block Monitor v3.8 (Self-Update by Cron Edition) ===
# ✅ ตรวจ HTTP + HTTPS แยก Block / Down / Online
# ✅ retry 2 ครั้ง ลด false block
# ✅ ส่งเข้า Telegram group + Bot Relay
# ✅ ล้าง cron เก่าอัตโนมัติ
# ✅ อัปเดตตัวเองทุกวัน (ดึง setup จาก GitHub มาลงใหม่)
# ❌ ไม่ยิงตรงเข้า Worker

# === CONFIG ===
GITHUB_SETUP="https://raw.githubusercontent.com/topfrom1982-wq/setup-scripts/main/lao-monitor-setup-v3.8.sh"
GITHUB_RAW="https://raw.githubusercontent.com/topfrom1982-wq/domains/main/domains.txt"
TG_TOKEN="8505152360:AAGOqN30EgVKVyN1J7dw4M3PgWeeaZrJLB4"
CHAT_ID="-4859960595"
ISP="Unitel"
RELAY_URL="https://telegram-relay.click18up.workers.dev/report"
TOKEN="top168"

SCRIPT_PATH="$HOME/lao-monitor.sh"
LOG_PATH="$HOME/lao-monitor.log"
DOMAIN_FILE="$HOME/domains.txt"
CRON_FILE="$PREFIX/var/spool/cron/crontabs/$(whoami)"

echo "🚀 ติดตั้ง Lao HTTPS Monitor (v3.8)..."
pkg update -y > /dev/null 2>&1
pkg install -y curl jq cronie termux-api > /dev/null 2>&1

echo "🧹 ล้างไฟล์เก่า..."
rm -f "$SCRIPT_PATH" "$LOG_PATH" "$DOMAIN_FILE"
sed -i "/lao-monitor.sh/d" "$CRON_FILE" 2>/dev/null
sed -i "/lao-monitor-setup-v3.8.sh/d" "$CRON_FILE" 2>/dev/null

# === MAIN SCRIPT ===
cat > "$SCRIPT_PATH" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# === JR x Top: Lao HTTPS Block Monitor (v3.7 Smart Detection + Bot Relay) ===

GITHUB_RAW="https://raw.githubusercontent.com/topfrom1982-wq/domains/main/domains.txt"
TG_TOKEN="8505152360:AAGOqN30EgVKVyN1J7dw4M3PgWeeaZrJLB4"
CHAT_ID="-4859960595"
ISP="Unitel"
RELAY_URL="https://telegram-relay.click18up.workers.dev/report"
TOKEN="top168"
DOMAIN_FILE="$HOME/domains.txt"
LOG="$HOME/lao-monitor.log"

# === ดึงโดเมนล่าสุดจาก GitHub ===
curl -s -o "$DOMAIN_FILE" "$GITHUB_RAW"
if [ ! -s "$DOMAIN_FILE" ]; then
  MSG="⚠️ [$ISP] ไม่พบโดเมนใน GitHub"
  curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "{\"chat_id\":${CHAT_ID}, \"text\":\"${MSG}\"}" > /dev/null
  exit 0
fi

echo "[$(date '+%H:%M:%S')] 🔍 เริ่มตรวจโดเมน..." >> "$LOG"

while read -r DOMAIN; do
  [[ -z "$DOMAIN" ]] && continue

  STATUS="❓ Unknown"

  # === ตรวจ 2 รอบ (retry 2 ครั้ง) ===
  for TRY in 1 2; do
    curl -Is --connect-timeout 5 "http://$DOMAIN" > /dev/null 2>&1
    HTTP_OK=$?
    curl -Is --connect-timeout 5 "https://$DOMAIN" > /dev/null 2>&1
    HTTPS_OK=$?

    if [ $HTTP_OK -eq 0 ] && [ $HTTPS_OK -ne 0 ]; then
      STATUS="🚫 Block"
    elif [ $HTTP_OK -ne 0 ] && [ $HTTPS_OK -ne 0 ]; then
      STATUS="❌ Down"
    elif [ $HTTP_OK -eq 0 ] && [ $HTTPS_OK -eq 0 ]; then
      STATUS="✅ Online"
    fi

    [ "$STATUS" != "❌ Down" ] && break
    sleep 2
  done

  MSG="[$ISP] ${DOMAIN} → ${STATUS}"

  # === 1️⃣ แจ้งใน Telegram group ===
  curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "{\"chat_id\":${CHAT_ID}, \"text\":\"${MSG}\"}" > /dev/null

  # === 2️⃣ ส่ง JSON รายงานเข้า Bot Relay ===
  STATUS_TEXT=""
  case "$STATUS" in
    "✅ Online") STATUS_TEXT="ok" ;;
    "🚫 Block") STATUS_TEXT="blocked" ;;
    "❌ Down") STATUS_TEXT="down" ;;
    *) STATUS_TEXT="unknown" ;;
  esac

  curl -s -X POST "$RELAY_URL" \
    -H "Content-Type: application/json" \
    -d "{\"isp\":\"${ISP}\",\"domain\":\"${DOMAIN}\",\"status\":\"${STATUS_TEXT}\",\"token\":\"${TOKEN}\"}" > /dev/null

  echo "[$(date '+%H:%M:%S')] ${DOMAIN} → ${STATUS}" >> "$LOG"
done < "$DOMAIN_FILE"

echo "[$(date '+%d/%m/%Y %H:%M:%S')] ✅ ตรวจครบแล้ว" >> "$LOG"
EOF

chmod +x "$SCRIPT_PATH"

# === ตั้ง cron ใหม่ ===
echo "📆 ตั้ง cron..."
mkdir -p "$(dirname "$CRON_FILE")"
sed -i "/lao-monitor.sh/d" "$CRON_FILE" 2>/dev/null
sed -i "/lao-monitor-setup-v3.8.sh/d" "$CRON_FILE" 2>/dev/null

# รัน monitor ทุก 10 นาที
echo "*/10 * * * * bash $SCRIPT_PATH" >> "$CRON_FILE"

# อัปเดตตัวเองทุกวัน ตี 4 (โหลด setup จาก GitHub มารัน)
echo "0 4 * * * curl -s $GITHUB_SETUP | bash > /dev/null 2>&1" >> "$CRON_FILE"

termux-wake-lock
crond

echo
echo "🎉 ติดตั้งเสร็จ (v3.8 — Cron Self-Update)"
echo "📌 ตรวจทุก 10 นาที + อัปเดตตัวเองทุกวัน ตี 4"
echo "📄 Log: $LOG_PATH"
