#!/data/data/com.termux/files/usr/bin/bash
# === JR x Top: Lao HTTPS Block Monitor v3.6 (Smart Detection Edition) ===
# ✅ ตรวจแม่นกว่าเดิม (HTTP+HTTPS)
# ✅ retry 2 ครั้ง ลด false block
# ✅ ล้าง cron เก่าก่อนตั้งใหม่
# ✅ ส่งผลเข้า Telegram โดยตรง (ไม่ผ่าน Worker)

# === CONFIG ===
GITHUB_RAW="https://raw.githubusercontent.com/topfrom1982-wq/domains/main/domains.txt"
TG_TOKEN="8505152360:AAGOqN30EgVKVyN1J7dw4M3PgWeeaZrJLB4"
CHAT_ID="-4859960595"
ISP="Unitel"

SCRIPT_PATH="$HOME/lao-monitor.sh"
LOG_PATH="$HOME/lao-monitor.log"
DOMAIN_FILE="$HOME/domains.txt"
CRON_FILE="$PREFIX/var/spool/cron/crontabs/$(whoami)"

echo "🚀 ติดตั้ง Lao HTTPS Monitor (v3.6)..."
pkg update -y > /dev/null 2>&1
pkg install -y curl jq cronie termux-api > /dev/null 2>&1

echo "🧹 ล้างของเก่าทั้งหมด..."
rm -f "$SCRIPT_PATH" "$LOG_PATH"
sed -i "/lao-monitor.sh/d" "$CRON_FILE" 2>/dev/null

# === MAIN SCRIPT ===
cat > "$SCRIPT_PATH" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# === JR x Top: Lao HTTPS Block Monitor (v3.6 Smart Detection) ===

GITHUB_RAW="https://raw.githubusercontent.com/topfrom1982-wq/domains/main/domains.txt"
TG_TOKEN="8505152360:AAGOqN30EgVKVyN1J7dw4M3PgWeeaZrJLB4"
CHAT_ID="-4859960595"
ISP="Unitel"
DOMAIN_FILE="$HOME/domains.txt"
LOG="$HOME/lao-monitor.log"

# === ดึงโดเมนล่าสุด ===
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

  # === ตรวจ 2 รอบ (retry) ===
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

    # ถ้าเจอ Online หรือ Block แล้ว ไม่ต้องเช็คซ้ำ
    [ "$STATUS" != "❌ Down" ] && break
    sleep 2
  done

  MSG="[$ISP] ${DOMAIN} → ${STATUS}"
  curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "{\"chat_id\":${CHAT_ID}, \"text\":\"${MSG}\"}" > /dev/null

  echo "[$(date '+%H:%M:%S')] ${DOMAIN} → ${STATUS}" >> "$LOG"
done < "$DOMAIN_FILE"

echo "[$(date '+%d/%m/%Y %H:%M:%S')] ✅ ตรวจครบแล้ว" >> "$LOG"
EOF

chmod +x "$SCRIPT_PATH"

# === ตั้ง cron ใหม่ (ทุก 10 นาที) ===
echo "📅 ตั้ง cron ใหม่..."
mkdir -p $(dirname "$CRON_FILE")
sed -i "/lao-monitor.sh/d" "$CRON_FILE" 2>/dev/null
echo "*/10 * * * * bash $SCRIPT_PATH" >> "$CRON_FILE"

termux-wake-lock
crond

echo ""
echo "✅ ติดตั้งเสร็จแล้ว (v3.6 Smart Detection)"
echo "-----------------------------------------"
echo "🌍 ISP: $ISP"
echo "📡 Source: $GITHUB_RAW"
echo "💬 ส่งเข้า Telegram group: $CHAT_ID"
echo "🕓 Interval: ทุก 10 นาที"
echo "📜 Log file: $LOG_PATH"
echo "-----------------------------------------"
