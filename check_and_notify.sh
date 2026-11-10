#!/usr/bin/env bash
# 采集本机（甲骨文 VPS）状态，并通过 PushDeer 推送每日通知
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  # shellcheck disable=SC1091
  set -a
  source "${SCRIPT_DIR}/.env"
  set +a
fi

PUSHDEER_KEY="${PUSHDEER_KEY:-}"
PUSHDEER_API="${PUSHDEER_API:-https://api2.pushdeer.com/message/push}"
NOTIFY_TITLE="${NOTIFY_TITLE:-甲骨文 VPS 状态}"

if [[ -z "${PUSHDEER_KEY}" ]]; then
  echo "错误：未设置 PUSHDEER_KEY（可在 .env 中配置）" >&2
  exit 1
fi

hostname_val="$(hostname 2>/dev/null || echo unknown)"
now_local="$(date '+%Y-%m-%d %H:%M:%S %Z')"
uptime_pretty="$(uptime -p 2>/dev/null || uptime | sed 's/^ //')"
load_avg="$(awk '{print $1", "$2", "$3}' /proc/loadavg 2>/dev/null || uptime | awk -F'load average:' '{print $2}' | sed 's/^ //')"

mem_line="N/A"
if command -v free >/dev/null 2>&1; then
  mem_line="$(free -h | awk '/^Mem:/{printf "已用 %s / 总计 %s（可用 %s）", $3, $2, $7}')"
fi

disk_line="N/A"
if command -v df >/dev/null 2>&1; then
  disk_line="$(df -h / | awk 'NR==2{printf "已用 %s / 总计 %s（%s）", $3, $2, $5}')"
fi

cpu_cores="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "?")"

public_ip="获取失败"
if command -v curl >/dev/null 2>/dev/null 2>&1; then
  public_ip="$(curl -fsS --max-time 8 https://ifconfig.me/ip 2>/dev/null \
    || curl -fsS --max-time 8 https://api.ipify.org 2>/dev/null \
    || echo "获取失败")"
fi

# 简单健康标记：根分区用量超过 90% 或 1 分钟负载 > 核心数*2 视为告警
status_emoji="✅"
status_text="正常"
root_pct="$(df -P / 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5); print $5}')"
load1="$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo 0)"
if [[ -n "${root_pct}" ]] && (( root_pct >= 90 )); then
  status_emoji="⚠️"
  status_text="磁盘紧张"
fi
if command -v awk >/dev/null 2>&1 && [[ "${cpu_cores}" =~ ^[0-9]+$ ]]; then
  if awk -v l="${load1}" -v c="${cpu_cores}" 'BEGIN{exit !(l > c*2)}'; then
    status_emoji="⚠️"
    status_text="负载偏高"
  fi
fi

title="${NOTIFY_TITLE} ${status_emoji} ${status_text}"
desp=$(cat <<EOF
**主机**: ${hostname_val}
**时间**: ${now_local}
**公网 IP**: ${public_ip}
**运行时长**: ${uptime_pretty}
**负载 (1/5/15)**: ${load_avg}
**CPU 核心**: ${cpu_cores}
**内存**: ${mem_line}
**根分区**: ${disk_line}
EOF
)

# PushDeer 支持 GET；对正文做 URL 编码
if command -v python3 >/dev/null 2>&1; then
  encoded_text="$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "${title}")"
  encoded_desp="$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "${desp}")"
elif command -v jq >/dev/null 2>&1; then
  encoded_text="$(jq -rn --arg v "${title}" '$v|@uri')"
  encoded_desp="$(jq -rn --arg v "${desp}" '$v|@uri')"
else
  echo "错误：需要 python3 或 jq 做 URL 编码" >&2
  exit 1
fi

url="${PUSHDEER_API}?pushkey=${PUSHDEER_KEY}&text=${encoded_text}&desp=${encoded_desp}"
resp="$(curl -fsS --max-time 20 "${url}")"
echo "PushDeer 响应: ${resp}"
echo "已推送: ${title}"
