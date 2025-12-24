# NetBird Self-Hosted - Quick Reference Guide

**Installation Date:** November 5, 2025
**Domain:** https://netbird.iyeska.net

---

## Access Information

**Dashboard:** https://netbird.iyeska.net
**Admin User:** admin@netbird.iyeska.net
**Password:** [Changed on November 5, 2025 - use your password manager]

Original installation password available in `NETBIRD_CREDENTIALS.txt` (reference only)

---

## Quick Commands

### Container Management
```bash
# View all containers
docker ps | grep netbird

# Restart all services
cd ~/netbird && docker-compose restart

# Stop all services
cd ~/netbird && docker-compose down

# Start all services
cd ~/netbird && docker-compose up -d

# View logs (follow)
docker logs netbird-management-1 -f
```

### Common Issues

**Management container restarting?**
```bash
docker logs netbird-management-1 --tail 20
docker restart netbird-management-1
```

**Can't access dashboard?**
```bash
# Check Caddy
docker logs netbird-caddy-1 --tail 20

# Verify port 443 is open
ss -tlnp | grep :443
```

**SSL certificate issues?**
```bash
# Check certificate
echo | openssl s_client -connect netbird.iyeska.net:443 2>/dev/null | openssl x509 -noout -dates
```

---

## Service Ports

- **80/TCP** - HTTP (redirects to HTTPS)
- **443/TCP** - HTTPS (Dashboard, API)
- **443/UDP** - HTTP/3 / QUIC
- **3478/UDP** - STUN
- **10000/TCP** - Signal gRPC
- **33073/UDP** - Signal WebRTC
- **33080/TCP** - Relay
- **49152-65535/UDP** - TURN port range

---

## Key Lessons

1. **Let's Encrypt Rate Limit:** 5 certs per domain per week
   - Solution: Used `netbird.iyeska.net` instead of `netbird.iyeska.net`

2. **Container Networking:** Don't add `/etc/hosts` entries for container-to-container communication
   - Containers use Docker internal DNS

3. **NAT Reflection:** Enabled in pfSense for internal access
   - Location: Firewall → NAT → Port Forward → Enable NAT reflection

---

## File Locations

- Installation: `/home/guthdx/netbird/`
- Credentials: `/home/guthdx/netbird/NETBIRD_CREDENTIALS.txt`
- Full Process Doc: `/home/guthdx/netbird/INSTALLATION_PROCESS.md`
- Docker Compose: `/home/guthdx/netbird/docker-compose.yml`
- Configs: `/home/guthdx/netbird/*.env`, `*.json`, `*.conf`

---

## Backup Command
```bash
# Quick backup
tar czf ~/netbird-backup-$(date +%Y%m%d).tar.gz ~/netbird/
```

---

## Emergency Recovery

**If everything breaks:**
```bash
# 1. Stop all
cd ~/netbird && docker-compose down -v

# 2. Clean up
rm -rf ~/netbird/*

# 3. Reinstall
curl -fsSL https://github.com/netbirdio/netbird/releases/latest/download/getting-started-with-zitadel.sh -o ~/netbird/netbird-install.sh
cd ~/netbird
export NETBIRD_DOMAIN=netbird.iyeska.net
bash netbird-install.sh
```

---

## Support Resources

- **NetBird Docs:** https://docs.netbird.io/
- **GitHub Issues:** https://github.com/netbirdio/netbird/issues
- **Community Forum:** https://forum.netbird.io/

---

**For detailed explanation of the installation process, see:** `INSTALLATION_PROCESS.md`
