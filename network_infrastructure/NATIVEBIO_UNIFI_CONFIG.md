# NativeBio - UniFi + pfSense Hybrid VLAN Configuration

**Date Implemented:** December 7, 2025
**Status:** ✅ Production - Hybrid VLAN Architecture
**Architecture:** UniFi Cloud Gateway (Office) + pfSense (Healthcare/PHI)

---

## Network Overview

**Public IP:** 192.168.100.100 (via SDN Co...)
**Device:** UniFi Cloud Gateway Max (UCG Max)
**Switch:** USW Pro XG 48-Port PoE

**Dual Network Architecture:**
```
Internet (WAN)
    ↓
UniFi Cloud Gateway Max
    ↓
USW Pro XG 48-Port Switch
    ├─ VLAN 1 (Default) - Office Network
    │   └─ Ports 1-32 → Office devices, workstations, APs
    │
    └─ VLAN 20 (NativeBio Secure) - Healthcare Network
        ├─ Port 33 → pfSense LAN (Third-party Gateway)
        └─ Ports 34-48 → Healthcare servers (PHI/REDCap)
```

---

## VLAN Configuration

### VLAN 1: Default (Office Network)

**Router:** UniFi Cloud Gateway Max
**Subnet:** 192.168.1.0/24
**Gateway:** 192.168.1.1
**DHCP:** Server (192.168.1.100-200)
**DNS:** 1.1.1.1, 8.8.8.8

**Purpose:** General office operations, workstations, WiFi, printers

**Connected Devices:**
- Office workstations
- WiFi Access Points (U7 Pro XGS x2)
- Network printers
- General office equipment
- Network Video Recorder

### VLAN 20: NativeBio Secure (Healthcare Network)

**Router:** Third-party Gateway (Protectli pfSense)
**Subnet:** 192.168.3.0/24
**Gateway:** 192.168.3.1 (pfSense)
**DHCP:** pfSense DHCP Server (192.168.3.100-150)
**DNS:** 192.168.3.1 (pfSense with filtering)

**Purpose:** Healthcare/PHI data, HIPAA-compliant infrastructure

**Connected Devices (via pfSense):**
- REDCap server (192.168.3.??)
- NativeBio Proxmox Server (192.168.3.30)
- TDR Proxmox Server (192.168.3.31)
- TDR VMs (tdrprimary, tdrdata, tdrbackup, etc.)
- Healthcare workstations
- Medical equipment

---

## Switch Port Configuration

### Port Layout

| Port Range | VLAN | Purpose | Profile |
|------------|------|---------|---------|
| 1-32 | 1 (Default) | Office Network | Access |
| 33 | 20 (NativeBio Secure) | pfSense LAN Uplink | Trunk |
| 34-48 | 20 (NativeBio Secure) | Healthcare Servers | Access |

### VLAN 1 (Office) - Ports 1-32

**Example Assignments:**
- Port 1-5: Office workstations
- Port 6-7: U7 Pro XGS WiFi Access Points (PoE)
- Port 8: Network Video Recorder
- Port 9-10: Network printers
- Ports 11-32: Available for expansion

### VLAN 20 (Healthcare) - Ports 33-48

**Port 33:** pfSense Uplink (Trunk)
- Connected to: Protectli pfSense Port 2 (LAN)
- Profile: Trunk/All VLANs
- Native VLAN: 20

**Ports 34-48:** Healthcare Servers (Access)
| Port | Device | IP Address |
|------|--------|------------|
| 34 | NativeBio Proxmox (pve) | 192.168.3.30 |
| 35 | TDR Proxmox (tdrpve) | 192.168.3.31 |
| 36 | tdrbackup | 192.168.3.240 |
| 37 | tdrportal | 192.168.3.241 |
| 38 | tdrwebsite (NBDC) | 192.168.3.242 |
| 39 | tdrdata | 192.168.3.243 |
| 40 | tdrcl | 192.168.3.244 |
| 41 | tdrgui | 192.168.3.245 |
| 42 | REDCap server | 192.168.3.?? |
| 43-48 | Available | - |

---

## pfSense Configuration (VLAN 20 Gateway)

**Device:** Protectli 6-Port pfSense Appliance

### Interface Configuration

**WAN (Port 1):**
- Public IP: 68.168.225.3 (static or DHCP from ISP)
- Purpose: Internet connection for healthcare network

**LAN (Port 2):**
- Connected to: Switch Port 33 (VLAN 20 trunk)
- IP Address: 192.168.3.1/24
- Purpose: Gateway for VLAN 20 (Healthcare network)

**Available Ports (3-6):**
- Reserved for future use (VPN, DMZ, management, failover)

### DHCP Configuration

**Interface:** LAN (VLAN 20)
- Enabled: ✅
- Range: 192.168.3.100 - 192.168.3.150
- DNS Servers: 1.1.1.1, 8.8.8.8
- Gateway: 192.168.3.1
- Domain Name: nativebio.local (optional)

### Firewall Rules

**LAN Interface Rules:**
```
Priority 1: Block RFC1918 outbound (prevent private IP leaks)
Priority 2: Allow healthcare servers to specific external services only
Priority 3: Allow internal healthcare workstations to servers
Priority 4: Default deny all else
```

**Specific Rules:**
```
# REDCap Server Outbound (minimal access)
Allow: 192.168.3.?? → External Port 443 (HTTPS) for updates
Allow: 192.168.3.?? → External Port 25 (SMTP) for email
Block: All other outbound from REDCap

# Healthcare Workstations
Allow: 192.168.3.20-30 → 192.168.3.?? Port 443 (REDCap access)
Allow: 192.168.3.20-30 → Internet (if needed)
Log: All connections for HIPAA audit
```

### Port Forwarding (WAN → LAN)

**TDR Infrastructure Access (via 68.168.225.3):**

| Service | WAN Port | Internal IP | Internal Port | Description |
|---------|----------|-------------|---------------|-------------|
| TDR Proxmox Web | 8007 | 192.168.3.31 | 8006 | Proxmox management |
| tdrdata SSH | 2222 | 192.168.3.243 | 22 | SSH access |
| tdrbackup SSH | 2227 | 192.168.3.240 | 22 | SSH access |
| tdrportal SSH | 2228 | 192.168.3.241 | 22 | SSH access |
| tdrwebsite SSH | 2229 | 192.168.3.242 | 22 | SSH access |
| tdrcl SSH | 2230 | 192.168.3.244 | 22 | SSH access |
| tdrgui SSH | 2231 | 192.168.3.245 | 22 | SSH access |
| REDCap HTTPS | 443 | 192.168.3.?? | 443 | REDCap web interface |

**All port forwards logged for HIPAA compliance**

### Security Packages

**Required Packages:**
1. **Suricata** - IDS/IPS
   - Interface: WAN
   - Mode: IPS (Inline mode - blocks threats)
   - Rulesets: Emerging Threats Open, HIPAA-specific rules
   - Logging: Full packet capture for security events
   - Alerts: Email to admin@nativebio.org

2. **pfBlockerNG** - Threat Intelligence
   - DNSBL: Enabled (block malicious domains)
   - IP Blocking: Emerging Threats, Spamhaus DROP/EDROP
   - Country Blocking: Optional (block non-US if appropriate)
   - Logging: All blocks logged for compliance

3. **ntopng** (Optional) - Network Traffic Analysis
   - Purpose: Forensics and traffic monitoring
   - Use: Breach investigation and compliance audits

---

## UniFi Cloud Gateway Configuration

### WAN Configuration

**Interface:** Internet 1 (WAN1)
- IP Address: 192.168.100.100
- ISP: SDN Co...
- Connection Type: DHCP or Static (per ISP)
- Uptime: 100%
- Status: ✅ Operational

### LAN Configuration

**Default Network (VLAN 1):**
- Subnet: 192.168.1.0/24
- Gateway: 192.168.1.1
- DHCP: Enabled (192.168.1.100-200)
- DNS: 1.1.1.1, 8.8.8.8

**NativeBio Secure Network (VLAN 20):**
- Type: **Third-party Gateway** (pfSense handles routing)
- VLAN ID: 20
- Subnet: None (pfSense manages this)
- DHCP: None (pfSense provides DHCP)
- Purpose: Layer 2 switching only

### WiFi Configuration

**Network:** NativeBio Clubhouse
- SSID: NativeBio Clubhouse
- Network: Native Network (VLAN 1)
- Broadcasting APs: All APs (2x U7 Pro XGS)
- WiFi Bands: 2.4 GHz, 5 GHz, 6 GHz
- Security: WPA2/WPA3
- Clients: 2 connected
- Purpose: Office WiFi (VLAN 1 only)

**Note:** Healthcare devices on VLAN 20 do NOT have WiFi access by design (wired only for security)

---

## Network Isolation & Security

### VLAN Separation

**Complete Layer 2 Isolation:**
- VLAN 1 (Office) and VLAN 20 (Healthcare) are completely separated
- No inter-VLAN routing configured
- Office network cannot access healthcare network directly
- Healthcare network cannot access office network

**Access to Healthcare Network:**
- Office staff can access REDCap via internet (through pfSense WAN)
- All access logged by pfSense for HIPAA compliance
- Traffic path: Office (VLAN 1) → Internet → pfSense WAN → REDCap (VLAN 20)

### Security Benefits

**VLAN 20 (Healthcare) Protected By:**
1. ✅ Complete network isolation from office
2. ✅ pfSense firewall with IDS/IPS (Suricata)
3. ✅ Threat intelligence blocking (pfBlockerNG)
4. ✅ Detailed audit logging (HIPAA-compliant)
5. ✅ Forensics capability (packet capture, ntopng)
6. ✅ Minimal internet exposure (only required services)
7. ✅ No WiFi access (wired only)

**VLAN 1 (Office) Protected By:**
1. ✅ UniFi built-in firewall
2. ✅ Default deny inbound policy
3. ✅ Guest network isolation (if configured)
4. ✅ Optional: CyberSecure+ ($99/year for enhanced IDS/IPS)

---

## HIPAA Compliance Readiness

### Documented Security Controls

1. **Network Segmentation:**
   - ✅ VLANs isolate PHI from general office network
   - ✅ Physical separation via switch port assignments
   - ✅ No inter-VLAN routing (air-gapped at Layer 2)

2. **Access Control:**
   - ✅ pfSense firewall controls all healthcare network access
   - ✅ Port forwarding limited to specific services only
   - ✅ All access logged for audit trail

3. **Intrusion Detection/Prevention:**
   - ✅ Suricata IDS/IPS monitors all healthcare network traffic
   - ✅ Threat intelligence feeds block known malicious IPs
   - ✅ Real-time alerts on security events

4. **Audit Logging:**
   - ✅ pfSense logs all firewall events (90 days minimum)
   - ✅ Suricata logs all IDS/IPS alerts (1 year)
   - ✅ REDCap access logs retained per HIPAA requirements

5. **Encryption:**
   - ✅ HTTPS enforced for all web services
   - ✅ SSH for all remote access
   - ✅ Data in transit encrypted

### Regular Security Reviews

**Weekly:**
- Review Suricata alerts for anomalies
- Check pfSense firewall logs for suspicious activity
- Verify all healthcare services operational

**Monthly:**
- Review access logs for compliance
- Update Suricata rulesets
- Verify backup integrity

**Quarterly:**
- Full security posture assessment
- Review and update firewall rules
- Test incident response procedures

**Annually:**
- HIPAA compliance audit
- Security policy review
- Update security documentation

---

## Backup & Recovery

### UniFi Configuration Backup

**Location:** UniFi Controller → Settings → Backup
- **Frequency:** Automatic daily backups
- **Retention:** 30 days
- **Download:** Settings → System → Backup → Download
- **Critical configs:** VLAN settings, port profiles, WiFi settings

### pfSense Configuration Backup

**Location:** Diagnostics → Backup & Restore
- **Frequency:** Manual backup before any changes
- **Storage:** Local download + offsite storage
- **Critical configs:** Firewall rules, port forwards, Suricata config, pfBlockerNG config

### Recovery Procedure

**If UniFi Cloud Gateway Fails:**
1. Adopt new UniFi Cloud Gateway
2. Restore configuration from backup
3. Verify VLAN 1 and VLAN 20 configuration
4. Test port assignments (especially port 33 to pfSense)
5. Verify all services operational

**If pfSense Fails:**
1. Install pfSense on replacement hardware
2. Restore configuration from backup
3. Verify WAN and LAN interfaces
4. Test port forwarding rules
5. Verify Suricata and pfBlockerNG operational
6. Test REDCap access from office and externally

---

## Performance Metrics

### UniFi Cloud Gateway Max

**Expected Throughput:**
- Without IDS/IPS: Up to 10 Gbps
- With CyberSecure+ IDS/IPS: ~5 Gbps (50% reduction)

**Current Setup:**
- IDS/IPS: Not enabled (adequate security via pfSense on VLAN 20)
- DPI: Enabled
- Expected performance: Full line rate for VLAN 1 traffic

### pfSense (VLAN 20)

**Expected Throughput:**
- Without Suricata: Varies by hardware (likely 1-5 Gbps)
- With Suricata IDS/IPS: ~40-60% reduction
- Typical: 500 Mbps - 2 Gbps with Suricata enabled

**Current Setup:**
- Suricata IDS/IPS: Enabled
- pfBlockerNG: Enabled
- Trade-off: Reduced throughput for enhanced security (appropriate for PHI)

---

## Troubleshooting

### Office Can't Access Internet (VLAN 1)

**Check:**
1. UniFi Cloud Gateway WAN status (should show 192.168.100.100)
2. DHCP clients getting 192.168.1.x addresses
3. Gateway set to 192.168.1.1
4. Test: `ping 8.8.8.8` from office device

**Fix:**
- Verify WAN connection to ISP
- Check UniFi Cloud Gateway online status
- Restart UniFi if needed

### Healthcare Servers Can't Access Internet (VLAN 20)

**Check:**
1. pfSense WAN status (68.168.225.3 assigned)
2. pfSense LAN interface (192.168.3.1) operational
3. Healthcare server gateway set to 192.168.3.1
4. Test: `ping 192.168.3.1` from healthcare server
5. Test: `ping 8.8.8.8` from healthcare server

**Fix:**
- Check pfSense → Status → Interfaces
- Verify firewall rules allow outbound traffic
- Check Suricata not blocking legitimate traffic
- Review pfSense logs: Status → System Logs → Firewall

### Office Can't Access REDCap

**Expected:** Office accesses REDCap via internet (through pfSense WAN)

**Check:**
1. From office browser: `https://redcap.nativebio.org` (or external URL)
2. Check pfSense port forward: WAN:443 → 192.168.3.??:443
3. Check pfSense firewall logs for blocks

**Fix:**
- Verify port forward exists and is enabled
- Check REDCap server is online (ping from pfSense)
- Review pfSense WAN firewall rules (should allow 443)

### Healthcare Devices Can't Communicate

**Check:**
1. Devices on correct switch ports (34-48)
2. Devices have 192.168.3.x IP addresses
3. Gateway set to 192.168.3.1
4. Can ping other devices on VLAN 20

**Fix:**
- Verify switch port profile is VLAN 20 (NativeBio Secure)
- Check device network settings
- Verify pfSense DHCP is serving addresses

### Port 33 (pfSense Uplink) Issues

**Check:**
1. Physical cable connected: Switch Port 33 ↔ pfSense Port 2
2. Switch port profile: Native VLAN 20, trunk mode
3. pfSense LAN interface: 192.168.3.1/24
4. Link status: Green in UniFi and pfSense

**Fix:**
- Verify cable is good (try different cable)
- Check port 33 configuration in UniFi
- Verify pfSense LAN interface is enabled
- Check for port speed/duplex mismatch

---

## Future Considerations

### Optional Enhancements

**1. Enable CyberSecure+ on UniFi (VLAN 1)**
- Cost: $99/year
- Benefit: IDS/IPS for office network
- Trade-off: 50% throughput reduction
- Recommendation: Enable if security needs increase

**2. Add Dedicated Healthcare Workstations on VLAN 20**
- Connect healthcare staff workstations to ports 43-48
- Provides direct access to REDCap (no internet routing)
- Enhanced security for healthcare staff
- Easier troubleshooting (no WAN dependency)

**3. VLAN Segmentation for IoT/Medical Devices**
- Create VLAN 30 for medical equipment
- Separate network for IoT devices (scales, monitors, etc.)
- Additional security isolation
- Easier to manage device firmware updates

**4. Multi-WAN Failover**
- Add secondary ISP connection to pfSense WAN2
- Automatic failover for healthcare network
- Improved uptime for critical services
- Cost: ~$100/month for second ISP

---

## Contact & Documentation

**Network Administrator:** Guthrie Ducheneaux (guthdx)
**Documentation Location:** `~/terminal_projects/claude_code/network_infrastructure/`

**Related Files:**
- `pfSense_vs_UniFi_Analysis.md` - Architecture decision rationale
- `NATIVEBIO_UNIFI_CONFIG.md` - This file (current configuration)
- `IYESKA_HQ_UNIFI_CONFIG.md` - Iyeska HQ reference configuration

**Support Resources:**
- UniFi Documentation: https://help.ui.com
- pfSense Documentation: https://docs.netgate.com/pfsense/
- HIPAA Compliance Guide: https://www.netgate.com/solutions/healthcare

---

**Configuration Status:** ✅ Production - Hybrid VLAN Architecture
**Last Updated:** December 7, 2025
**Next Review:** January 7, 2026

**Architecture Summary:**
- Office Network (VLAN 1): UniFi Cloud Gateway - Simple, unified management
- Healthcare Network (VLAN 20): pfSense Gateway - HIPAA-compliant, enhanced security
- Complete isolation between networks
- Best of both worlds: Simplicity for office, security for PHI
