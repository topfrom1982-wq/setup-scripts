#!/data/data/com.termux/files/usr/bin/bash
# === JR x Top: Lao Domain Monitor Auto Setup (Telegram Relay Edition v2.5) ===
# ✅ ติดตั้ง, ล้างของเก่า, ตั้ง cron, เปิด wakelock และรันอัตโนมัติ
# ✅ ใช้ได้ทันทีบน Termux มือถือทุกเครื่อง

MONITOR_API="https://domain-monitor.click18up.workers.dev"
TOKEN="top168"
ISP="Unitel"
TG_TOKEN="8505152360:AAGOqN30EgVKVyN1J7dw4M3PgWeeaZrJLB4"
RELAY_URL="https://telegram-relay.click18up.workers.dev"
SCRIPT_PATH="$HOME/lao-check.sh"
LOG_PATH="$HOME/lao-monitor.log"
CRON_FILE="$PREFIX/var/spool/cron/crontabs/$(whoami)"

echo "🚀 เริ่มติดตั้ง Lao Domain Monitor..."
pkg update -y > /dev/null 2>&1
pkg install -y curl jq cronie termux-api > /dev/null 2>&1

echo "🧹 ล้างของเก่า..."
rm -f "$SCRIPT_PATH" "$LOG_PATH"
sed -i "/lao-check.sh/d" "$CRON_FILE" 2>/dev/null

echo "📝 กำลังสร้างสคริปต์ใหม่..."

cat > "$SCRIPT_PATH" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# === JR x Top: Lao Domain Monitor (Telegram Relay Edition v2.1) ===
# ✅ ดึงโดเมนจาก Worker KV → ตรวจ Ping → ส่งผลผ่าน Telegram Relay
# ✅ ใช้กับมือถือ Termux ได้ทันที ไม่ต้องเปิดจอไว้

MONITOR_API="https://domain-monitor.click18up.workers.dev"
TOKEN="top168"
ISP="Unitel"
LOG="$HOME/lao-monitor.log"

# === Telegram Relay Config ===
TG_TOKEN="8505152360:AAGOqN30EgVKVyN1J7dw4M3PgWeeaZrJLB4"
RELAY_URL="https://telegram-relay.click18up.workers.dev"

echo "[$(date '+%d/%m/%Y %H:%M:%S')] 🔍 เริ่มตรวจโดเมน..." >> "$LOG"

# ✅ ดึงรายการโดเมนจาก Worker
DOMAINS=$(curl -s "$MONITOR_API/list" | jq -r '.domains[]')

if [ -z "$DOMAINS" ]; then
  echo "[$(date '+%H:%M:%S')] ⚠️ ไม่มีโดเมนในลิสต์" >> "$LOG"
  exit 0
fi

# === Loop ตรวจทุกโดเมน ===
for DOMAIN in $DOMAINS; do
  PING_RESULT=$(ping -c 1 -W 2 $DOMAIN 2>/dev/null)
  if echo "$PING_RESULT" | grep -q "1 received"; then
    STATUS="OK"
    LATENCY=$(echo "$PING_RESULT" | grep 'time=' | sed 's/.*time=\([0-9.]*\).*/\1/')
  else
    STATUS="DOWN"
    LATENCY=0
  fi

  # === ส่งผลผ่าน Telegram Relay ===
  MESSAGE="relay:${MONITOR_API}/report?token=${TOKEN}|${ISP}|${DOMAIN}|${STATUS}|${LATENCY}"
  curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
       -H "Content-Type: application/json" \
       -d "{\"chat_id\":0, \"text\": \"${MESSAGE}\"}" \
       > /dev/null

  echo "[$(date '+%H:%M:%S')] $DOMAIN → $STATUS (${LATENCY}ms)" >> "$LOG"
done

echo "[$(date '+%d/%m/%Y %H:%M:%S')] ✅ ตรวจครบแล้ว" >> "$LOG"
EOF

chmod +x "$SCRIPT_PATH"

echo "📅 ตั้ง cron ทุก 10 นาที..."
mkdir -p $(dirname "$CRON_FILE")
echo "*/10 * * * * bash $SCRIPT_PATH" >> "$CRON_FILE"

echo "🔒 เปิดโหมดกันจอดับ..."
termux-wake-lock

echo "🚀 เริ่ม cron daemon..."
crond

echo ""
echo "✅ ติดตั้งสำเร็จ!"
echo "-----------------------------------------"
echo "🌍 ISP: $ISP"
echo "📡 Worker: $MONITOR_API"
echo "🔑 Token: $TOKEN"
echo "📊 Dashboard: $MONITOR_API/dashboard"
echo "🕓 Interval: ทุก 10 นาที"
echo "📜 Log file: $LOG_PATH"
echo "-----------------------------------------"
echo "ระบบจะเริ่มตรวจในรอบถัดไป..."
EOF
