#!/usr/bin/env bash
# 安装每日定时任务（默认每天 09:00，Asia/Shanghai）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_SCRIPT="${SCRIPT_DIR}/check_and_notify.sh"
LOG_FILE="${SCRIPT_DIR}/notify.log"
CRON_HOUR="${CRON_HOUR:-9}"
CRON_MINUTE="${CRON_MINUTE:-0}"

chmod +x "${NOTIFY_SCRIPT}"

if [[ ! -f "${SCRIPT_DIR}/.env" ]]; then
  if [[ -f "${SCRIPT_DIR}/.env.example" ]]; then
    cp "${SCRIPT_DIR}/.env.example" "${SCRIPT_DIR}/.env"
    echo "已生成 .env，请填入 PUSHDEER_KEY 后再运行一次本脚本。"
    exit 1
  fi
  echo "缺少 .env" >&2
  exit 1
fi

cron_line="${CRON_MINUTE} ${CRON_HOUR} * * * cd ${SCRIPT_DIR} && /usr/bin/env bash ${NOTIFY_SCRIPT} >> ${LOG_FILE} 2>&1"

# 去掉旧条目后追加
tmp="$(mktemp)"
crontab -l 2>/dev/null | grep -v "${NOTIFY_SCRIPT}" >"${tmp}" || true
echo "${cron_line}" >>"${tmp}"
crontab "${tmp}"
rm -f "${tmp}"

echo "已安装 cron："
echo "  ${cron_line}"
echo "可立即试跑： ${NOTIFY_SCRIPT}"
