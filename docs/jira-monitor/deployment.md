# 🚀 Deployment

> *Build → Transfer → Deploy to sys-butalam01*

## Quick Commands

```bash
# Deploy jiramntr
cd ~/projects/jiramntr && ./scripts/deploy_butalam.sh

# Deploy johanna
cd ~/projects/johanna && ./scripts/deploy_butalam.sh
```

## Server Layout

| Path | Service | Managed By |
|------|---------|-----------|
| `/opt/jiramntr/` | DWH + BI + KPI server | manual (`./run.sh`) |
| `/opt/johanna/` | AI Chat server | systemd (`johanna.service`) |

## Build Process

1. `switch_env.sh butalam` → load production `.env`
2. `CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build` → Linux binary
3. Package: binary + .env + config + ui + ai + scripts + database
4. `scp` tarball → remote `/tmp/`
5. Remote: extract, apply DDL, restart

## Service Control

```bash
# Johanna (systemd)
sudo systemctl start|stop|restart johanna
sudo journalctl -u johanna -f

# Jiramntr (manual)
cd /opt/jiramntr && nohup ./run.sh > logs/server.log &
```

## Environment Files

```
opt/envs/.env_butalam    ← production
opt/envs/.env_local      ← local dev
```

Switch: `./scripts/switch_env.sh butalam`

## Network

| Service | Host | Port |
|---------|------|------|
| SSH | `ssh -i ~/.ssh/butala nemetg@sys-butalam01` | 22 |
| PostgreSQL | localhost | 5432 |
| Jiramntr | sys-butalam01 | 8080 |
| Johanna | sys-butalam01 | 8082 |
| Ollama | sys-gpu01.alig.hu | 11434 |
| LDAP | ldap.alig.hu | 389 |
