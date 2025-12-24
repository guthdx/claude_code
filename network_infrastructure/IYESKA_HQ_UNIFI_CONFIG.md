# Iyeska HQ - UniFi Cloud Gateway Max Configuration

**Date Implemented:** December 5, 2025
**Status:** ✅ Production - All Services Operational
**Architecture:** 100% UniFi (pfSense eliminated)

---

## Network Overview

**Public IP:** 68.168.225.52
**Internal Network:** 192.168.11.0/24
**Gateway:** UniFi Cloud Gateway Max
**Device Count:** 12+ active devices

**Architecture:**
```
Internet (68.168.225.52)
    ↓
UniFi Cloud Gateway Max (WAN1: Internet 1)
    ↓
UniFi Switch (USW-Lite-16-PoE)
    ↓
Devices on 192.168.11.0/24
```

---

## Port Forwarding Configuration

**Total Rules:** 12 active port forwards

### NetBird VPN Server (192.168.11.20)

Critical for cross-machine connectivity and remote access:

| Service | Protocol | WAN Port | Forward IP | Forward Port | Purpose |
|---------|----------|----------|------------|--------------|---------|
| NetBird Relay Range | UDP | 49152-65535 | 192.168.11.20 | 49152-65535 | Peer relay connections |
| NetBird STUN | UDP | 3478 | 192.168.11.20 | 3478 | NAT traversal |
| NetBird Relay Service | TCP | 33080 | 192.168.11.20 | 33080 | Relay coordination |
| NetBird Signal | TCP | 10000 | 192.168.11.20 | 10000 | Signaling server |
| NetBird TURN | UDP | 33073 | 192.168.11.20 | 33073 | TURN relay |
| NetBird HTTP | TCP | 80 | 192.168.11.20 | 80 | Let's Encrypt HTTP-01 |
| NetBird HTTPS | TCP | 443 | 192.168.11.20 | 443 | Dashboard/API access |

**Access:** https://netbird.iyeska.net

### Infrastructure Services

| Service | Protocol | WAN Port | Forward IP | Forward Port | Purpose |
|---------|----------|----------|------------|--------------|---------|
| Quantum Storage | TCP/UDP | 5000 | 192.168.11.12 | 5000 | NAS file access |
| n8n Automation | TCP | 5678 | 192.168.11.20 | 5678 | Workflow automation |

**Access:**
- Storage: Port 5000
- n8n: https://n8n.iyeska.net (via Cloudflare)

### SSH Access

| Service | WAN Port | Forward IP | Forward Port | Device |
|---------|----------|------------|--------------|--------|
| SSH Iyeska | 2022 | 192.168.11.20 | 22 | Ubuntu server (NetBird host) |
| SSH RaspberriPi | 2024 | 192.168.11.16 | 22 | Raspberry Pi NAS |
| SSH Mac Mini | 2025 | 192.168.11.17 | 22 | Mac Mini (Ollama server) |

**Usage:** `ssh -p [PORT] guthdx@68.168.225.52`

---

## Key Devices

### 192.168.11.20 - Iyeska Ubuntu 24.04 Server
- **Services:** NetBird management/signal, n8n, Docker host
- **Ports:** 80, 443, 10000, 3478, 33073, 33080, 5678, 49152-65535
- **Access:** SSH via port 2022

### 192.168.11.12 - Quantum Storage
- **Services:** NAS, file storage
- **Ports:** 5000
- **Access:** Direct port or via Cloudflare (nas.iyeska.net)

### 192.168.11.16 - Raspberry Pi NAS
- **Services:** Network storage, Pi NAS
- **Ports:** SSH (2024)
- **Access:** SSH via port 2024, web via pinas.iyeska.net

### 192.168.11.17 - Mac Mini
- **Services:** Ollama API (code.iyeska.net), remote AI models
- **Ports:** SSH (2025), 11434 (Ollama)
- **Access:** SSH via port 2025, API via Cloudflare tunnel

---

## Cloudflare Tunnel Services

These services bypass port forwarding and use Cloudflare tunnels for access:

| Domain | Backend | Service |
|--------|---------|---------|
| n8n.iyeska.net | 192.168.11.20:5678 | Workflow automation |
| nas.iyeska.net | 192.168.11.12:5000 | Storage access |
| pinas.iyeska.net | 192.168.11.16 | Pi NAS web interface |
| recap.iyeska.net | 192.168.11.20:8088 | REDCap (if hosted here) |
| stoic.iyeska.net | 192.168.11.20:3333 | Stoic service |
| wowasi.iyeska.net | 192.168.11.20:8001 | Wowasi documentation generator |
| code.iyeska.net | 192.168.11.17:11434 | Ollama AI API (Mac Mini) |
| dna.iyeska.net | 192.168.11.20:3001 | DNA Spectrum app |
| netbird.iyeska.net | 68.168.225.52:443 | NetBird dashboard (DNS A record) |

**Note:** Cloudflare tunnels use outbound connections, so they work regardless of port forwarding.

---

## Migration from pfSense

**Previous Architecture (REMOVED):**
```
Internet → pfSense (192.168.20.1) → UniFi CGW (192.168.20.10) → Devices (192.168.11.x)
```

**Issues with Old Setup:**
- ❌ Double NAT (two layers of address translation)
- ❌ Complex port forwarding (had to configure on both pfSense AND UniFi)
- ❌ Performance overhead
- ❌ Two management interfaces
- ❌ Difficult troubleshooting

**Current Architecture (IMPLEMENTED):**
```
Internet → UniFi Cloud Gateway Max → Devices (192.168.11.x)
```

**Benefits:**
- ✅ Single NAT layer
- ✅ Direct port forwarding
- ✅ Unified management
- ✅ Better performance
- ✅ Simplified troubleshooting
- ✅ NetBird VPN works from remote locations

---

## Security Configuration

### Firewall Rules
- Default deny inbound (except forwarded ports)
- Allow all outbound
- No UPnP enabled
- Guest network isolated (if configured)

### UniFi Threat Management
- Status: Available (not currently enabled)
- IDS/IPS: Can enable if needed ($99/yr CyberSecure+)
- Trade-off: ~50% throughput reduction if enabled

**Recommendation:** Enable threat management if security requirements increase or if handling sensitive data.

### Current Security Posture
- ✅ Port forwarding to specific IPs only
- ✅ SSH on non-standard ports (2022, 2024, 2025)
- ✅ HTTPS for web services
- ✅ NetBird VPN for internal access
- ✅ Cloudflare tunnels for additional services (encrypted)

---

## Verification & Testing

**Tested from:** Missouri Breaks (68.168.224.236)

### Port Connectivity Tests (Dec 5, 2025)
- ✅ Port 443 (HTTPS): Connected
- ✅ Port 80 (HTTP): Connected
- ✅ Port 2022 (SSH): Connected
- ✅ NetBird Dashboard: Loading
- ✅ NetBird VPN: Connected from remote location

### Service Availability
- ✅ NetBird VPN operational
- ✅ n8n accessible via Cloudflare
- ✅ SSH access working
- ✅ Storage services accessible
- ✅ Ollama API responding (code.iyeska.net)

---

## Troubleshooting

### NetBird Connection Issues

**Symptom:** Can't connect to NetBird from remote location

**Check:**
1. Verify port forwards are active in UniFi
2. Check NetBird containers running: `docker ps | grep netbird`
3. Test ports: `nc -zv 68.168.225.52 10000`
4. Check NetBird logs: `docker logs netbird-signal`

### SSH Access Issues

**Symptom:** Can't SSH to devices

**Check:**
1. Verify port forwards (2022, 2024, 2025)
2. Ensure using correct port: `ssh -p 2022 guthdx@68.168.225.52`
3. Check if service is running on target device

### General Connectivity

**From remote location:**
```bash
# Test basic reachability
ping 68.168.225.52

# Test specific ports
nc -zv 68.168.225.52 443
nc -zv 68.168.225.52 2022

# Test Cloudflare services
curl https://n8n.iyeska.net
```

**From local network (192.168.11.x):**
```bash
# Access services directly via internal IP
ssh guthdx@192.168.11.20
curl http://192.168.11.20:5678  # n8n
```

---

## Backup & Recovery

### UniFi Configuration Backup
- **Location:** UniFi Controller → Settings → Backup
- **Frequency:** Automatic daily backups
- **Download:** Settings → System → Backup → Download

### Critical Configurations to Document
- ✅ Port forwarding rules (documented above)
- ✅ Network settings (192.168.11.0/24)
- ✅ WiFi settings
- ✅ VLANs (if configured)

### Recovery Procedure
1. Factory reset UniFi Cloud Gateway
2. Adopt to UniFi Controller
3. Restore configuration from backup
4. Verify port forwards
5. Test all services

---

## Performance Metrics

**Expected Throughput:**
- Without IDS/IPS: Up to 10 Gbps (limited by WAN connection)
- With IDS/IPS: ~5 Gbps (50% reduction)

**Current Setup:**
- IDS/IPS: Disabled
- DPI: Enabled
- Expected performance: Full line rate

**NetBird VPN Performance:**
- Eliminates double NAT overhead
- Direct peer-to-peer when possible
- Relay via Iyeska HQ when needed

---

## Future Considerations

### Optional Enhancements

**1. Enable Threat Management**
- Cost: $99/year (UniFi CyberSecure+)
- Benefit: IDS/IPS protection
- Trade-off: 50% throughput reduction
- Recommendation: Enable if security needs increase

**2. Multi-WAN Setup**
- Add secondary ISP connection
- Automatic failover
- Load balancing
- Benefit: Improved uptime

**3. VLANs for Segmentation**
- Separate IoT devices
- Guest network isolation
- Server/service segmentation
- Enhanced security posture

---

## Maintenance Schedule

### Weekly
- Review UniFi dashboard for alerts
- Check NetBird peer connectivity
- Verify all Cloudflare tunnels operational

### Monthly
- Review port forwarding rules
- Check for UniFi firmware updates
- Verify backup configurations
- Test SSH access from external location

### Quarterly
- Full service verification
- Security posture review
- Performance metrics analysis
- Consider enabling IDS/IPS if not active

---

## Contact & Documentation

**Network Administrator:** guthdx
**Documentation Location:** `~/terminal_projects/claude_code/network_infrastructure/`
**Related Files:**
- `pfSense_vs_UniFi_Analysis.md` - Decision rationale
- `IYESKA_HQ_UNIFI_CONFIG.md` - This file

**Support Resources:**
- UniFi Documentation: https://help.ui.com
- NetBird Documentation: https://netbird.io/docs
- Cloudflare Zero Trust: https://developers.cloudflare.com/cloudflare-one/

---

**Configuration Status:** ✅ Production
**Last Verified:** December 5, 2025
**Next Review:** January 5, 2026
