# 甲骨文 VPS → PushDeer 每日状态通知

在 Oracle Cloud（甲骨文）VPS 上采集主机状态，每天通过 [PushDeer](https://www.pushdeer.com/) 推送到手机。

## 推送内容

- 主机名、时间、公网 IP
- 运行时长、负载、CPU 核心数
- 内存与根分区用量
- 磁盘紧张 / 负载偏高时标题带告警标记

## 快速开始

1. 把本仓库放到 VPS（或本机克隆后 scp）：

```bash
git clone https://github.com/cafefrappe/o.git ~/oracle-vps-pushdeer
cd ~/oracle-vps-pushdeer
cp .env.example .env
# 编辑 .env，填入 PUSHDEER_KEY
```

2. 试跑一次：

```bash
chmod +x check_and_notify.sh install-cron.sh
./check_and_notify.sh
```

3. 安装每日 09:00 cron：

```bash
./install-cron.sh
```

自定义时间（例如每天 21:30）：

```bash
CRON_HOUR=21 CRON_MINUTE=30 ./install-cron.sh
```

## 环境变量

| 变量 | 说明 |
|------|------|
| `PUSHDEER_KEY` | PushDeer 推送密钥（必填） |
| `NOTIFY_TITLE` | 通知标题前缀，默认「甲骨文 VPS 状态」 |
| `PUSHDEER_API` | API 地址，默认 `https://api2.pushdeer.com/message/push` |

密钥只放在 `.env` 中，不要提交到 Git。

## 依赖

- `bash`、`curl`
- `python3` 或 `jq`（URL 编码）

## 日志

cron 输出写入同目录 `notify.log`。
