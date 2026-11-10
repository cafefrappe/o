#!/usr/bin/env bash
# 在甲骨文 VPS 上安装每日采集+GitHub 代推任务（默认每天 09:00）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_SCRIPT="${SCRIPT_DIR}/vps_dispatch.sh"
LOG_FILE="${SCRIPT_DIR}/notify.log"
CRON_HOUR="${CRON_HOUR:-9}"
CRON_MINUTE="${CRON_MINUTE:-0}"

chmod +x "${NOTIFY_SCRIPT}" "${SCRIPT_DIR}/collect_status.sh"

if [[ ! -f "${SCRIPT_DIR}/.env" ]]; then
  echo "缺少 .env（需含 GH_DISPATCH_TOKEN）" >&2
  exit 1
fi

if ! grep -q '^GH_DISPATCH_TOKEN=' "${SCRIPT_DIR}/.env"; then
  echo "请在 .env 中设置 GH_DISPATCH_TOKEN" >&2
  exit 1
fi

cron_line="${CRON_MINUTE} ${CRON_HOUR} * * * cd ${SCRIPT_DIR} && /usr/bin/env bash ${NOTIFY_SCRIPT} >> ${LOG_FILE} 2>&1"

tmp="$(mktemp)"
crontab -l 2>/dev/null | grep -v "${SCRIPT_DIR}/vps_dispatch.sh" | grep -v "${SCRIPT_DIR}/check_and_notify.sh" >"${tmp}" || true
echo "${cron_line}" >>"${tmp}"
crontab "${tmp}"
rm -f "${tmp}"

echo "已安装 VPS cron："
echo "  ${cron_line}"
echo "可立即试跑： ${NOTIFY_SCRIPT}"
