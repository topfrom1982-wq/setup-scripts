#!/data/data/com.termux/files/usr/bin/bash
# === JR x Top: Lao Domain Monitor Auto Installer (GitHub + Telegram Relay v3.0) ===
# ✅ ติดตั้ง, ตั้ง cron, ดึงโดเมนอัตโนมัติ, ตรวจบล็อค, ส่งบอท, เชื่อม Worker
# ✅ ใช้ได้ทันทีบน Termux มือถือทุกเครื่อง (ฝั่งลาว)

# === CONFIG ===
GITHUB_RAW="https://raw.githubusercontent.com/topfrom1982-wq/domains/main/domains.txt"
MONITOR_API="https://domain-monitor.click18up.workers.dev"
RELAY_URL="https://telegram-relay.click18up.workers.dev"
TG_TOKEN="8505152360:AAGOqN30EgVKVyN1J7dw4M3PgWeeaZrJLB4"
TOKEN="top168"
ISP="Unitel"

SCRIPT_PATH="$HOME/lao-monitor.sh"
LOG_PATH="$HOME/lao-monitor.log"
DOMAIN_FILE="$HOME/domains.txt"
CRON_FILE="$PREFIX/var/spool/cron/crontabs/$(whoami)"

echo "🚀 กำลังติดตั้ง Lao Domain Monitor (v3.0)..."
pkg update -y > /dev/null 2>&1
pkg install -y curl jq cronie termux-api > /dev/null 2>&1

echo "🧹 ล้างสคริปต์เก่า..."
rm -f "$SCRIPT_PATH" "$LOG_PATH"
sed -i "/lao-monitor.sh/d" "$CRON_FILE" 2>/dev/null

# === MAIN SCRIPT ===
cat > "$SCRIPT_PATH" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# === JR x Top: Lao Domain Monitor (GitHub Sync + Telegram Relay Edition v3.0) ===
GITHUB_RAW="https://raw.githubusercontent.com/topfrom1982-wq/domains/main/domains.txt"
MONITOR_API="https://domain-monitor.click18up.workers.dev"
TG_TOKEN="8505152360:AAGOqN30EgVKVyN1J7dw4M3PgWeeaZrJLB4"
TOKEN="top168"
ISP="Unitel"
DOMAIN_FILE="$HOME/domains.txt"
LOG="$HOME/lao-monitor.log"

echo "[$(date '+%d/%m/%Y %H:%M:%S')] 🔄 เริ่มอัปเดตโดเมน..." >> "$LOG"
curl -s -o "$DOMAIN_FILE" "$GITHUB_RAW"

if [ ! -s "$DOMAIN_FILE" ]; then
  echo "[$(date '+%H:%M:%S')] ⚠️ ไม่พบโดเมนใน GitHub" >> "$LOG"
  exit 0
fi

while read -r DOMAIN; do
  [[ -z "$DOMAIN" ]] && continue
  echo "[$(date '+%H:%M:%S')] ⏳ ตรวจ $DOMAIN..." >> "$LOG"
  RESPONSE=$(curl -Is --max-time 5 "https://$DOMAIN" 2>/dev/null | head -n 1)
  if echo "$RESPONSE" | grep -q "200\|301\|302"; then
    STATUS="OK"
  else
    STATUS="BLOCKED"
  fi
  LATENCY=$(ping -c 1 -W 2 $DOMAIN 2>/dev/null | grep 'time=' | sed 's/.*time=\([0-9.]*\).*/\1/')
  LATENCY=${LATENCY:-0}

  MESSAGE="relay:${MONITOR_API}/report?token=${TOKEN}|${ISP}|${DOMAIN}|${STATUS}|${LATENCY}"
  curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "{\"chat_id\":0, \"text\": \"${MESSAGE}\"}" > /dev/null

  echo "[$(date '+%H:%M:%S')] $DOMAIN → $STATUS (${LATENCY}ms)" >> "$LOG"
done < "$DOMAIN_FILE"

echo "[$(date '+%d/%m/%Y %H:%M:%S')] ✅ ตรวจครบแล้ว" >> "$LOG"
EOF

chmod +x "$SCRIPT_PATH"

# === ตั้ง CRON ให้รันทุก 10 นาที ===
echo "📅 ตั้ง cron ทุก 10 นาที..."
mkdir -p $(dirname "$CRON_FILE")
echo "*/10 * * * * bash $SCRIPT_PATH" >> "$CRON_FILE"

# === ป้องกันมือถือดับหน้าจอ ===
termux-wake-lock

# === เริ่ม daemon ===
crond

echo ""
echo "✅ ติดตั้งเสร็จเรียบร้อย!"
echo "-----------------------------------------"
echo "🌍 ISP: $ISP"
echo "📡 Worker: $MONITOR_API"
echo "🔗 Domains: $GITHUB_RAW"
echo "📊 Dashboard: $MONITOR_API/dashboard"
echo "🕓 Interval: ทุก 10 นาที"
echo "📜 Log file: $LOG_PATH"
echo "-----------------------------------------"
echo "ระบบจะเริ่มทำงานโดยอัตโนมัติในรอบถัดไป..."
EOF
