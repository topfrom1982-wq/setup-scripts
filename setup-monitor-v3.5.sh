#!/data/data/com.termux/files/usr/bin/bash
# === JR x Top: Lao HTTPS Block Monitor (v3.5 Bot Relay Edition) ===
# ✅ ตรวจโดเมน HTTPS ว่าถูกบล็อคหรือไม่ (จำลอง browser header ให้แม่นกว่าเดิม)
# ✅ รายงานผลผ่าน Telegram Bot เท่านั้น (ไม่ต่อ Workers อีก)
# ✅ ล้างข้อมูลเก่าก่อนลงใหม่
# ✅ ตั้ง cron ทุก 10 นาที + ป้องกัน sleep ด้วย termux-wake-lock

# === CONFIG ===
GITHUB_RAW="https://raw.githubusercontent.com/topfrom1982-wq/domains/main/domains.txt"
TG_TOKEN="8505152360:AAGOqN30EgVKVyN1J7dw4M3PgWeeaZrJLB4"
CHAT_ID="-4859960595"
ISP="Unitel"

SCRIPT_PATH="$HOME/lao-monitor.sh"
LOG_PATH="$HOME/lao-monitor.log"
DOMAIN_FILE="$HOME/domains.txt"
CRON_FILE="$PREFIX/var/spool/cron/crontabs/$(whoami)"

echo "🚀 กำลังติดตั้ง Lao HTTPS Monitor (v3.5 Bot Relay Edition)..."

# === ติดตั้งแพ็กเกจที่จำเป็น ===
pkg update -y > /dev/null 2>&1
pkg install -y curl jq cronie termux-api > /dev/null 2>&1

# === ล้างข้อมูลเก่าทั้งหมด ===
echo "🧹 ล้างสคริปต์และ cron เก่าทั้งหมด..."
rm -f "$SCRIPT_PATH" "$LOG_PATH" "$DOMAIN_FILE"
sed -i '/lao-monitor.sh/d' "$CRON_FILE" 2>/dev/null
crontab -r 2>/dev/null

# === MAIN SCRIPT ===
cat > "$SCRIPT_PATH" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# === JR x Top: Lao HTTPS Block Monitor (v3.5) ===
# ส่งผลเข้า Telegram เท่านั้น

GITHUB_RAW="https://raw.githubusercontent.com/topfrom1982-wq/domains/main/domains.txt"
TG_TOKEN="8505152360:AAGOqN30EgVKVyN1J7dw4M3PgWeeaZrJLB4"
CHAT_ID="-4859960595"
ISP="Unitel"
DOMAIN_FILE="$HOME/domains.txt"
LOG="$HOME/lao-monitor.log"

# ดึงโดเมนล่าสุดจาก GitHub
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

  # ใช้ curl จำลอง browser header ให้แม่นกว่าการบล็อคจริง
  RESPONSE=$(curl -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" \
                 -H "Accept: text/html" \
                 -H "Accept-Language: en-US,en;q=0.9" \
                 -o /dev/null -s -w "%{http_code} %{time_connect} %{time_starttransfer} %{remote_ip}" \
                 --connect-timeout 8 --max-time 10 -L "https://$DOMAIN")

  CODE=$(echo "$RESPONSE" | awk '{print $1}')
  TIME_CONNECT=$(echo "$RESPONSE" | awk '{print $2}')
  TIME_START=$(echo "$RESPONSE" | awk '{print $3}')
  IP=$(echo "$RESPONSE" | awk '{print $4}')

  if [[ "$CODE" == "200" || "$CODE" == "301" || "$CODE" == "302" ]]; then
    STATUS="✅ Online"
  else
    STATUS="🚫 Block"
  fi

  MSG="[$ISP] ${DOMAIN} → ${STATUS}"
  curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "{\"chat_id\":${CHAT_ID}, \"text\":\"${MSG}\"}" > /dev/null

  echo "[$(date '+%H:%M:%S')] ${DOMAIN} → ${STATUS} (IP:${IP} CODE:${CODE} LAT:${TIME_START}s)" >> "$LOG"
done < "$DOMAIN_FILE"

echo "[$(date '+%d/%m/%Y %H:%M:%S')] ✅ ตรวจครบแล้ว" >> "$LOG"
EOF

chmod +x "$SCRIPT_PATH"

# === ตั้ง CRON ทุก 10 นาที ===
echo "📅 ตั้ง cron ทุก 10 นาที..."
mkdir -p "$(dirname "$CRON_FILE")"
echo "*/10 * * * * bash $SCRIPT_PATH" > "$CRON_FILE"

termux-wake-lock
crond

echo ""
echo "✅ ติดตั้งเรียบร้อยแล้ว (v3.5 Bot Relay Edition)"
echo "-----------------------------------------"
echo "🌍 ISP: $ISP"
echo "📡 Source: $GITHUB_RAW"
echo "💬 ส่งเข้า Telegram group: $CHAT_ID"
echo "🕓 Interval: ทุก 10 นาที"
echo "📜 Log file: $LOG_PATH"
echo "-----------------------------------------"
