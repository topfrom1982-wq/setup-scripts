#!/data/data/com.termux/files/usr/bin/bash
# === JR x Top: Lao HTTPS Block Monitor v3.8 (Self-Update Edition) ===
# ✅ ตรวจ HTTP + HTTPS แยก Block / Down / Online
# ✅ retry 2 รอบ ลด false block
# ✅ แจ้ง Telegram group + Bot Relay
# ✅ ใช้ token top168
# ✅ Self-update (อัปเดตตัวเองจาก GitHub)
# ❌ ไม่ยิงตรง Worker

# ------------------------------------------------
# CONFIG
# ------------------------------------------------
GITHUB_SCRIPT="https://raw.githubusercontent.com/topfrom1982-wq/setup-scripts/main/lao-monitor.sh"
GITHUB_RAW="https://raw.githubusercontent.com/topfrom1982-wq/domains/main/domains.txt"

TG_TOKEN="8505152360:AAGOqN30EgVKVyN1J7dw4M3PgWeeaZrJLB4"
CHAT_ID="-4859960595"
ISP="Unitel"

RELAY_URL="https://telegram-relay.click18up.workers.dev/report"
TOKEN="top168"

SCRIPT_PATH="$HOME/lao-monitor.sh"
LOG="$HOME/lao-monitor.log"
DOMAIN_FILE="$HOME/domains.txt"

# ------------------------------------------------
# SELF-UPDATE CHECK
# ------------------------------------------------
NEW_TMP="$HOME/lao-monitor-new.sh"

curl -s -o "$NEW_TMP" "$GITHUB_SCRIPT"

if [ -s "$NEW_TMP" ]; then
  if ! diff -q "$SCRIPT_PATH" "$NEW_TMP" > /dev/null 2>&1; then
    echo "♻️ พบเวอร์ชันใหม่ → อัปเดตตัวเอง..." >> "$LOG"
    mv "$NEW_TMP" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    bash "$SCRIPT_PATH"
    exit 0
  fi
fi

rm -f "$NEW_TMP"

# ------------------------------------------------
# ดาวน์โหลดรายชื่อโดเมน
# ------------------------------------------------
curl -s -o "$DOMAIN_FILE" "$GITHUB_RAW"

if [ ! -s "$DOMAIN_FILE" ]; then
  MSG="⚠️ [$ISP] ไม่พบโดเมนใน GitHub"
  curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
       -H "Content-Type: application/json" \
       -d "{\"chat_id\":${CHAT_ID}, \"text\":\"${MSG}\"}" > /dev/null
  exit 0
fi

echo "[$(date '+%H:%M:%S')] 🔍 เริ่มตรวจโดเมน..." >> "$LOG"

# ------------------------------------------------
# LOOP ตรวจโดเมนทั้งหมด
# ------------------------------------------------
while read -r DOMAIN; do
  [[ -z "$DOMAIN" ]] && continue

  STATUS="❓ Unknown"

  for TRY in 1 2; do
    curl -Is --connect-timeout 5 "http://$DOMAIN" > /dev/null 2>&1
    HTTP_OK=$?

    curl -Is --connect-timeout 5 "https://$DOMAIN" > /dev/null 2>&1
    HTTPS_OK=$?

    if   [ $HTTP_OK -eq 0 ] && [ $HTTPS_OK -ne 0 ]; then STATUS="🚫 Block"
    elif [ $HTTP_OK -ne 0 ] && [ $HTTPS_OK -ne 0 ]; then STATUS="❌ Down"
    elif [ $HTTP_OK -eq 0 ] && [ $HTTPS_OK -eq 0 ]; then STATUS="✅ Online"
    fi

    [ "$STATUS" != "❌ Down" ] && break
    sleep 2
  done

  MSG="[$ISP] ${DOMAIN} → ${STATUS}"

  # ส่ง Telegram group
  curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
       -H "Content-Type: application/json" \
       -d "{\"chat_id\":${CHAT_ID}, \"text\":\"${MSG}\"}" > /dev/null

  # ส่ง Bot Relay
  STATUS_TEXT=""
  case "$STATUS" in
    "✅ Online") STATUS_TEXT="ok" ;;
    "🚫 Block")  STATUS_TEXT="blocked" ;;
    "❌ Down")   STATUS_TEXT="down" ;;
    *)          STATUS_TEXT="unknown" ;;
  esac

  curl -s -X POST "$RELAY_URL" \
       -H "Content-Type: application/json" \
       -d "{\"isp\":\"${ISP}\",\"domain\":\"${DOMAIN}\",\"status\":\"${STATUS_TEXT}\",\"token\":\"${TOKEN}\"}" > /dev/null

  echo "[$(date '+%H:%M:%S')] ${DOMAIN} → ${STATUS}" >> "$LOG"

done < "$DOMAIN_FILE"

echo "[$(date '+%d/%m/%Y %H:%M:%S')] ✅ ตรวจครบแล้ว" >> "$LOG"
