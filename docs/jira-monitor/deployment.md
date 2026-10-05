# 🚀 Deployment

> *Build → Transfer → Deploy to the prod server*

## Quick Commands

```bash
# Deploy jiramntr
cd ~/projects/jiramntr && ./scripts/<deploy script>

# Deploy johanna
cd ~/projects/johanna && ./scripts/<deploy script>
```

## Server Layout

| Path | Service | Managed By |
|------|---------|-----------|
| `/opt/jiramntr/` | DWH + BI + KPI server | manual (`./run.sh`) |
| `/opt/johanna/` | AI Chat server | systemd (`johanna.service`) |

## Build Process

1. `switch_env.sh <prod profile>` → load production `.env`
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
opt/envs/.env_<prod>     ← production
opt/envs/.env_local      ← local dev
```

Switch: `./scripts/switch_env.sh <prod profile>`

## Network

| Service | Host | Port |
|---------|------|------|
| SSH | `ssh <user>@<prod server>` | 22 |
| PostgreSQL | localhost | 5432 |
| Jiramntr | prod server | 8080 |
| Johanna | prod server | 8082 |
| Ollama | GPU server | 11434 |
| LDAP | Active Directory | 389 |
