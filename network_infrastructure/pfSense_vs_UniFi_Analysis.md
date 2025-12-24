# pfSense vs UniFi Cloud Gateway: Network Architecture Decision

**Date:** December 5, 2025
**Decision:** Multi-site network infrastructure upgrade
**Current State:** Hybrid setup with pfSense + UniFi Cloud Gateway (double NAT)

---

## Executive Summary

**Recommendation:** Differentiated strategy - use UniFi Cloud Gateway for 75% of sites, keep pfSense for high-security healthcare site.

**Primary Benefits:**
- Eliminate double NAT across all locations
- Reduce management overhead (5-10 hours/month saved)
- Improve NetBird VPN performance
- Maintain compliance at healthcare site (NativeBio)

**Investment:** ~$900 first year, $300/year ongoing
**ROI:** Pays for itself in first month via time savings

---

## Current Problem: The Double NAT Trap

**Architecture:**
```
Internet → pfSense (WAN) → pfSense (LAN) → UniFi Cloud Gateway (WAN) → UniFi Switches → Devices
```

**Issues:**
- Double NAT breaks NetBird VPN performance (9 forwarded ports)
- Two management interfaces (pfSense + UniFi)
- Two points of failure
- Performance overhead
- Complex troubleshooting

---

## Feature Comparison

| Feature | pfSense | UniFi Cloud Gateway | Winner |
|---------|---------|-------------------|--------|
| **Multi-Site Management** | Manual per site | Centralized controller | 🏆 UniFi |
| **IDS/IPS Security** | Suricata + full config | Suricata + basic config | 🏆 pfSense |
| **Healthcare/PHI Compliance** | Excellent logging/audit | Basic (adequate with CyberSecure+) | 🏆 pfSense |
| **Unified Ecosystem** | Separate from UniFi | Native integration | 🏆 UniFi |
| **Package Ecosystem** | 50+ packages | None | 🏆 pfSense |
| **Client Reporting** | Technical | Business-friendly | 🏆 UniFi |
| **Remote Management** | VPN required | Cloud-based | 🏆 UniFi |
| **Multi-WAN/Failover** | Sophisticated | Basic | 🏆 pfSense |
| **VPN Capabilities** | Extensive | Basic WireGuard/L2TP | 🏆 pfSense |
| **Learning Curve** | Steep | Gentle | 🏆 UniFi |
| **Configurability** | Maximum | Limited | 🏆 pfSense |

---

## Critical Finding: IDS/IPS Performance Impact

Both platforms use **Suricata** for IDS/IPS, with significant performance penalties:

| Device | Without IDS/IPS | With IDS/IPS | Performance Hit |
|--------|----------------|--------------|-----------------|
| UDM Pro Max | 10 Gbps | 5 Gbps | 50% |
| UDM Pro | 8 Gbps | 3.5 Gbps | 56% |
| pfSense | Varies by hardware | Varies | ~40-60% |

**Key Difference:** pfSense's Suricata implementation is "way more configurable" with better alert management and forensics capabilities.

---

## Site-Specific Recommendations

### Category A: Standard Business Sites (3 locations)
**Sites:** Iyeska HQ, TDR, Missouri Breaks
**Solution:** UniFi Cloud Gateway (UCG-Max or UDM Pro)
**Add-On:** CyberSecure+ ($99/year) for enhanced security

**Why:**
- Unified management across all sites
- Adequate security for business operations
- Eliminate double NAT
- Modern UI for client reporting
- Cost-effective

**Architecture:**
```
Internet → UniFi Cloud Gateway → UniFi Switches → Devices/APs
```

### Category B: High-Security Healthcare Site (1 location)
**Site:** NativeBio (REDCap with PHI)
**Solution:** pfSense as primary router
**Packages:** Suricata IDS/IPS + pfBlockerNG

**Why:**
- HIPAA compliance requirements
- Detailed audit logging for regulatory audits
- Advanced threat protection (IDS/IPS + threat intelligence)
- Forensics capability for breach investigation
- Maximum configurability

**Architecture:**
```
Internet → pfSense → UniFi Switch → REDCap Server/Devices
```
*Note: UniFi devices still centrally managed via controller*

### Category C: NetBird VPN Host
**Current:** Ubuntu server at 192.168.11.20
**Solution:** UniFi Cloud Gateway as primary router

**Why:**
- **Eliminates double NAT** (critical for VPN performance)
- Simplifies port forwarding (9 ports: 80, 443, 10000, 3478, 33073, 33080, 49152-65535/UDP)
- Easier troubleshooting
- Better VPN throughput

---

## Migration Plan

### Phase 1: Quick Win (Week 1-2)
**Target:** NetBird VPN host site

**Steps:**
1. Purchase UniFi UCG-Max ($199) or UDM Pro ($379)
2. Subscribe to CyberSecure+ ($99/year)
3. Schedule 2-hour maintenance window
4. Backup pfSense config
5. Move public IP to UniFi WAN
6. Replicate firewall rules and port forwards
7. Test NetBird connectivity thoroughly
8. Monitor for 1 week

**Expected Result:** Immediate VPN performance improvement, simpler management

### Phase 2: Standard Sites (Month 2-3)
**Targets:** Iyeska HQ, TDR, Missouri Breaks

**Strategy:** One site per week
1. Build UniFi template configuration
2. Schedule maintenance windows (low-usage hours)
3. Migrate and monitor for 48 hours before next site
4. Document lessons learned

### Phase 3: Healthcare Site Optimization (Month 4)
**Target:** NativeBio

**Strategy:** Keep pfSense, optimize for compliance
1. Enable and configure Suricata IDS/IPS
2. Install and configure pfBlockerNG
3. Set up detailed compliance logging
4. Document security controls for HIPAA audits
5. Maintain UniFi switches/APs behind pfSense

---

## Cost Analysis

### Hardware Investment

**UniFi Cloud Gateway Options:**
- **UCG-Max:** $199 (recommended for standard sites)
- **UDM Pro:** $379 (more ports, better performance)
- **UDM Pro Max:** $700 (2.5/10 Gbps, best performance)

**pfSense:**
- Existing hardware: $0
- New Netgate appliance: $400-$2,000 (if needed)

### Subscriptions

**UniFi CyberSecure+:** $99/year per site
- Enhanced IDS/IPS signature database
- Advanced logging and reporting
- Compliance-focused features

**pfSense:** $0 (open source)
- Optional Netgate TAC support: $399-$999/year

### Total Investment (Recommended Configuration)

**Year 1:**
- 3x UniFi UCG-Max: $600
- 3x CyberSecure+: $300
- NativeBio pfSense: $0 (existing)
- **Total:** ~$900

**Ongoing:**
- CyberSecure+ renewals: $300/year

### ROI Calculation

**Time Savings:**
- Multi-site management: 5-10 hours/month
- Standardized configs: Fewer unique issues
- Faster troubleshooting: Single pane of glass

**Value:** 5-10 hours × $120/hr = $600-$1,200/month
**Payback Period:** Less than 1 month

---

## Why Not One Solution for Everything?

### If You Choose UniFi Everywhere:
**Pros:**
- Maximum simplification
- Lowest management overhead
- Consistent experience

**Cons:**
- ❌ Weaker security at NativeBio (healthcare/PHI)
- ❌ Limited IDS/IPS configurability
- ❌ May not meet HIPAA audit requirements
- ❌ No advanced packages (pfBlockerNG, ntopng)

### If You Choose pfSense Everywhere:
**Pros:**
- Maximum security at all sites
- Advanced features everywhere
- Most flexible/configurable

**Cons:**
- ❌ No multi-site management
- ❌ Manual config replication
- ❌ Higher management overhead
- ❌ Underutilizing UniFi investment

### The Hybrid Approach (Recommended):
**Pros:**
- ✅ Right tool for each job
- ✅ Security where it matters (NativeBio)
- ✅ Simplicity where appropriate (standard sites)
- ✅ Maximize UniFi investment
- ✅ Maintain compliance posture

**Cons:**
- Two management systems (but only 2 vs 4+ pfSense boxes)

---

## Healthcare/Compliance Considerations

### Can UniFi Meet HIPAA Requirements?

**Technical Answer:** Yes, with UDM Pro Max + CyberSecure+

**Practical Answer:** pfSense is still better for NativeBio because:

1. **Audit Depth:** HIPAA auditors expect detailed logs; pfSense provides more comprehensive logging
2. **Configurability:** Risk assessments require documented controls; pfSense allows granular tuning
3. **Maturity:** Established track record in healthcare environments
4. **Defense-in-Depth:** Additional packages (pfBlockerNG, Suricata) add security layers
5. **Forensics:** Breach investigation requires packet capture and detailed logs

**Recommendation:** For sites with PHI, the extra capabilities justify the management overhead.

---

## Key Takeaways

1. **No Double NAT Anywhere** - Every site gets clean routing (Internet → Primary Router → Devices)

2. **Differentiated Strategy** - Use the right tool for each site's requirements
   - Standard sites → UniFi (simplicity)
   - Healthcare site → pfSense (security)

3. **Start with NetBird Site** - Immediate benefit from eliminating double NAT affecting VPN

4. **Unified Management Where Possible** - 3 sites managed from single UniFi controller

5. **Maintain Security Where Critical** - NativeBio keeps pfSense for HIPAA compliance

6. **Time Savings = ROI** - Multi-site management efficiency pays for hardware in first month

---

## Post-Migration Network Diagram

```
📍 Iyeska HQ:
Internet → UniFi UCG-Max → UniFi Switches → Devices/APs ✅

📍 TDR:
Internet → UniFi UCG-Max → UniFi Switches → Devices/APs ✅

📍 Missouri Breaks:
Internet → UniFi UCG-Max → UniFi Switches → Devices/APs ✅

📍 NativeBio (REDCap/PHI):
Internet → pfSense (Suricata IDS/IPS) → UniFi Switch → Devices/APs ✅
                                                     ↓
                                              REDCap Server

📍 NetBird VPN Host:
Internet → UniFi UCG-Max → NetBird Server (Docker) ✅
           (9 ports forwarded + UDP range 49152-65535)
```

**Management Interfaces:**
- UniFi Controller: Manages 3-4 sites (routers, switches, APs)
- pfSense Web UI: Manages NativeBio only
- Total: 2 interfaces (vs 4+ separate pfSense instances currently)

---

## Decision Drivers Summary

| Factor | Weight | Winner | Notes |
|--------|--------|--------|-------|
| Multi-Site Management | High | UniFi | 5-10 hrs/month savings |
| Healthcare Compliance | Critical | pfSense | HIPAA audit requirements |
| NetBird VPN Performance | High | UniFi | Eliminate double NAT |
| Cost | Medium | UniFi | $900 investment, fast ROI |
| Learning Curve | Medium | UniFi | Easier for staff/clients |
| Advanced Security | Site-Specific | Both | Use where needed |

---

## Resources & Documentation

**pfSense:**
- Official Docs: https://docs.netgate.com/pfsense/
- Suricata Package: https://docs.netgate.com/pfsense/en/latest/packages/suricata/
- HIPAA Compliance Guide: https://www.netgate.com/solutions/healthcare

**UniFi:**
- IDS/IPS Documentation: https://help.ui.com/hc/en-us/articles/360006893234
- UDM Pro Max Specs: https://store.ui.com/us/en/collections/unifi-gateway
- CyberSecure+ Info: https://ui.com/cybersecurity

**Performance Research:**
- UniFi Threat Management Analysis: https://community.ui.com/questions/UDM-Pro-Threat-Management-Throughput-20percent-hit
- pfSense vs UniFi Comparison: https://set-inform.com/2020/02/23/i-dont-love-unifi-threat-management

---

## Next Steps

- [ ] Purchase 3x UniFi UCG-Max routers
- [ ] Subscribe to CyberSecure+ for 3 sites
- [ ] Schedule maintenance window for NetBird site migration
- [ ] Document NetBird port forwarding requirements
- [ ] Build UniFi template configuration
- [ ] Plan NativeBio pfSense optimization
- [ ] Document security controls for HIPAA compliance
- [ ] Create backup strategy for all devices

---

**Document Version:** 3.0
**Last Updated:** December 7, 2025
**Author:** Network Infrastructure Review
**Status:** ✅ IMPLEMENTED at Iyeska HQ and Missouri Breaks

## Implementation Update (Dec 5, 2025)

**✅ Iyeska HQ migrated to 100% UniFi Cloud Gateway Max**
- Eliminated pfSense completely
- Removed double NAT architecture
- Direct port forwarding from WAN (68.168.225.52) to internal services
- NetBird VPN operational
- All services confirmed working (n8n, storage, SSH, NetBird)
- Simplified management with unified UniFi dashboard

**Architecture Changes:**
- Before: Internet → pfSense (192.168.20.1) → UniFi → 192.168.11.x (Double NAT ❌)
- After: Internet → UniFi (68.168.225.52) → 192.168.11.x (Single NAT ✅)

**Benefits Realized:**
- ✅ No double NAT performance penalty
- ✅ Simplified troubleshooting (one device instead of two)
- ✅ Single management interface
- ✅ NetBird VPN works from remote locations (tested from Missouri Breaks)
- ✅ All 12 port forwards working correctly

---

## Implementation Update (Dec 7, 2025)

**✅ Missouri Breaks migrated to 100% UniFi Cloud Gateway**
- Eliminated pfSense completely
- Removed double NAT architecture
- Direct internet access via UniFi Cloud Gateway
- Network running on 192.168.0.0/24 subnet
- All services operational
- Simplified management with unified UniFi dashboard

**Architecture Changes:**
- Before: Internet → pfSense (68.168.224.236) → UniFi → 192.168.x.x (Double NAT ❌)
- After: Internet → UniFi (68.168.224.236) → 192.168.0.x (Single NAT ✅)

**Benefits Realized:**
- ✅ No double NAT performance penalty
- ✅ Simplified troubleshooting (one device instead of two)
- ✅ Single management interface
- ✅ Clean network architecture
- ✅ Faster network performance
