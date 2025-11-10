#!/data/data/com.termux/files/usr/bin/bash
# === JR x Top: Lao HTTPS Block Monitor (v3.2 Minimal Edition) ===
# ✅ เช็คเฉพาะการบล็อค HTTPS
# ✅ ดึงโดเมนจาก GitHub และส่งผลเข้า Telegram โดยตรง
# ✅ ใช้ได้ทันทีบน Termux มือถือฝั่งลาว

# === CONFIG ===
GITHUB_RAW="https://raw.githubusercontent.com/topfrom1982-wq/domains/main/domains.txt"
TG_TOKEN="8505152360:AAGOqN30EgVKVyN1J7dw4M3PgWeeaZrJLB4"
CHAT_ID="-4859960595"   # กลุ่ม Domain Laos
ISP="Unitel"

SCRIPT_PATH="$HOME/lao-monitor.sh"
LOG_PATH="$HOME/lao-monitor.log"
DOMAIN_FILE="$HOME/domains.txt"
CRON_FILE="$PREFIX/var/spool/cron/crontabs/$(whoami)"

echo "🚀 กำลังติดตั้ง Lao HTTPS Monitor (v3.2)..."
pkg update -y > /dev/null 2>&1
pkg install -y curl jq cronie termux-api > /dev/null 2>&1

echo "🧹 ล้างของเก่า..."
rm -f "$SCRIPT_PATH" "$LOG_PATH"
sed -i "/lao-monitor.sh/d" "$CRON_FILE" 2>/dev/null

# === MAIN SCRIPT ===
cat > "$SCRIPT_PATH" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# === JR x Top: Lao HTTPS Block Monitor (v3.2) ===

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

  # ตรวจ HTTPS — ถ้า TLS/SSL fail หรือ reset ถือว่า Block
  curl -Is --connect-timeout 5 "https://$DOMAIN" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    STATUS="✅ Online"
  else
    STATUS="🚫 Block"
  fi

  MSG="[$ISP] ${DOMAIN} → ${STATUS}"
  curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "{\"chat_id\":${CHAT_ID}, \"text\":\"${MSG}\"}" > /dev/null

  echo "[$(date '+%H:%M:%S')] ${DOMAIN} → ${STATUS}" >> "$LOG"
done < "$DOMAIN_FILE"

echo "[$(date '+%d/%m/%Y %H:%M:%S')] ✅ ตรวจครบแล้ว" >> "$LOG"
EOF

chmod +x "$SCRIPT_PATH"

# === ตั้ง CRON ให้รันทุก 10 นาที ===
echo "📅 ตั้ง cron ทุก 10 นาที..."
mkdir -p $(dirname "$CRON_FILE")
echo "*/10 * * * * bash $SCRIPT_PATH" >> "$CRON_FILE"

termux-wake-lock
crond

echo ""
echo "✅ ติดตั้งเรียบร้อยแล้ว!"
echo "-----------------------------------------"
echo "🌍 ISP: $ISP"
echo "📡 Source: $GITHUB_RAW"
echo "💬 ส่งเข้า Telegram group: $CHAT_ID"
echo "🕓 Interval: ทุก 10 นาที"
echo "📜 Log file: $LOG_PATH"
echo "-----------------------------------------"
EOF
