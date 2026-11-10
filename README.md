# 甲骨文 VPS → PushDeer 每日状态通知

对齐 [workbuddy-vps-ops](https://github.com/cafefrappe/workbuddy-vps-ops) 已跑通方案：

```
GitHub Actions ──SSH──► VPS 采集状态 ──► PushDeer
（不依赖 Mac 在线）
```

海外 VPS 直连 `api2.pushdeer.com` 会超时，所以由 Actions 代推。

## 一次性配置（与 WorkBuddy 相同的 3 个 Secrets）

打开：https://github.com/cafefrappe/o/settings/secrets/actions  

| Name | 填什么 |
|------|--------|
| `PUSHDEER_KEY` | 本仓库用的 `PDU…` 密钥 |
| `VPS_HOST` | `ubuntu@147.224.133.110` |
| `VPS_SSH_KEY` | SSH 私钥 Base64 单行（推荐） |

生成 `VPS_SSH_KEY`：

```bash
base64 < ~/.ssh/ssh-key-2026-06-17.key | pbcopy
```

然后：`Actions` → `PushDeer VPS Status` → `Run workflow` 手动试一次。

定时：每天 **09:00 北京时间**。

## VPS 上只需采集脚本

```bash
git clone https://github.com/cafefrappe/o.git ~/oracle-vps-pushdeer
chmod +x ~/oracle-vps-pushdeer/collect_status.sh
```

不必在 VPS 上装 PushDeer 直推 cron。

## 推送内容

- 主机名、时间、公网 IP
- 运行时长、负载、CPU
- 内存、根分区
- 磁盘/负载异常时标题告警

## 脚本

| 文件 | 作用 |
|------|------|
| `.github/workflows/pushdeer-notify.yml` | Actions：SSH 采集 + 推送 |
| `collect_status.sh` | VPS：只采集状态 |
