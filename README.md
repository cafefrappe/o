# 甲骨文 VPS → PushDeer 每日状态通知

海外甲骨文 VPS **直连不了** PushDeer（`api2.pushdeer.com`），本方案不依赖 Mac 在线：

1. **VPS** 每天采集状态  
2. 调用 GitHub API 触发 Actions  
3. **GitHub Actions** 代推 PushDeer  

## 一次性配置

### A. GitHub 仓库 Secrets

打开：https://github.com/cafefrappe/o/settings/secrets/actions  

新增：

| Name | Value |
|------|-------|
| `PUSHDEER_KEY` | 你的 PushDeer 密钥 |

### B. 创建 GitHub PAT（给 VPS 用）

1. https://github.com/settings/tokens  
2. 生成 classic token，勾选 `repo`（或 fine-grained：对该仓库允许触发 workflow / 读写）  
3. 只保存在 VPS 的 `.env`，不要提交仓库  

### C. VPS 部署

```bash
git clone https://github.com/cafefrappe/o.git ~/oracle-vps-pushdeer
cd ~/oracle-vps-pushdeer
cp .env.example .env
nano .env   # 填入 GH_DISPATCH_TOKEN=...
chmod +x *.sh
./vps_dispatch.sh    # 试跑：应触发 Actions，手机收到通知
./install-cron.sh    # 默认每天 09:00（配合 crontab 里 TZ=Asia/Shanghai）
```

## 推送内容

- 主机名、时间、公网 IP  
- 运行时长、负载、CPU  
- 内存、根分区  
- 磁盘/负载异常时标题告警  

## 脚本

| 脚本 | 作用 |
|------|------|
| `collect_status.sh` | 只采集状态 |
| `vps_dispatch.sh` | VPS：采集并触发 GitHub Actions |
| `install-cron.sh` | 安装 VPS 每日 cron |
| `mac_relay_notify.sh` | 可选：Mac 在线时代推（非必需） |

## 说明

- Mac **不需要**全天在线  
- 公开仓库中不含 PushDeer 密钥与 PAT  
- Actions 工作流：`.github/workflows/pushdeer-notify.yml`  
