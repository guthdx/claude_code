# AD Group Policy Drive Mapping Troubleshooting

## Issue
Windows error: "An error occurred while reconnecting R: to \\ibrfileserver\shared drive 2"
- "Microsoft Windows Network: The local device name is already in use."
- "This connection has not been restored."

**Important**: Drive is assigned by Active Directory Group Policy (cannot manually disconnect/reconnect)

## Root Cause Analysis

Since the drive is policy-assigned, the "already in use" error typically means:

1. **Stale connection** - Previous connection didn't close cleanly
2. **Network connectivity issue** - Can't reach `ibrfileserver`
3. **Authentication failure** - Kerberos ticket expired or credential issue
4. **DNS resolution problem** - Can't resolve `ibrfileserver` hostname
5. **VPN/NetBird not connected** - If this is a remote server
6. **File server offline** - `ibrfileserver` may be down

## Troubleshooting Steps

### 1. Check Current Drive Mappings
```cmd
net use
```
Look for any existing R: mapping - might show as "Unavailable" or "Disconnected"

### 2. Test Network Connectivity to File Server
```cmd
REM Ping the server
ping ibrfileserver

REM Test SMB connectivity
net view \\ibrfileserver

REM Test specific share
dir "\\ibrfileserver\shared drive 2"
```

### 3. Check DNS Resolution
```cmd
nslookup ibrfileserver
```
Should return an IP address. If it fails, DNS issue.

### 4. Verify Authentication/Kerberos
```cmd
REM List cached Kerberos tickets
klist

REM Purge and refresh tickets
klist purge
gpupdate /force
```

### 5. Force Group Policy Refresh
```cmd
REM As Administrator
gpupdate /force

REM Then logoff and logon again (or reboot)
shutdown /r /t 0
```

### 6. Check if VPN/NetBird is Connected
If `ibrfileserver` is on a remote network:
- Ensure NetBird VPN is connected (check system tray)
- Test connectivity: `ping 192.168.11.x` (adjust to actual server IP)
- Check NetBird peers: NetBird UI → Peers → Verify `ibrfileserver` is online

### 7. Manual Cleanup (Temporary Workaround)
If you need immediate access while IT investigates:

```cmd
REM As Administrator - force disconnect stale connection
net use R: /delete /yes

REM Then force GP refresh
gpupdate /force
```

**Warning**: This will only work temporarily. The policy will try to remap on next login.

## If Server is on NetBird Infrastructure

Based on repository context, if this is part of the Iyeska infrastructure:

1. **Check NetBird Dashboard**: https://netbird.iyeska.net
   - Verify peer status
   - Check if `ibrfileserver` is online

2. **Verify Server is Reachable**:
   ```cmd
   ping 192.168.11.x  (replace with actual IP)
   ```

3. **Check NetBird Logs**:
   ```bash
   # On the NetBird server (SSH)
   cd ~/netbird
   docker compose logs -f management
   ```

## Quick Diagnostic Script

Run this in PowerShell as Administrator:

```powershell
Write-Host "=== AD Drive Mapping Diagnostics ===" -ForegroundColor Cyan

Write-Host "`n1. Current drive mappings:" -ForegroundColor Yellow
net use

Write-Host "`n2. Testing ibrfileserver connectivity:" -ForegroundColor Yellow
Test-Connection -ComputerName ibrfileserver -Count 2 -ErrorAction SilentlyContinue

Write-Host "`n3. DNS resolution:" -ForegroundColor Yellow
Resolve-DnsName ibrfileserver -ErrorAction SilentlyContinue

Write-Host "`n4. Testing SMB share:" -ForegroundColor Yellow
Test-Path "\\ibrfileserver\shared drive 2" -ErrorAction SilentlyContinue

Write-Host "`n5. Kerberos tickets:" -ForegroundColor Yellow
klist

Write-Host "`n=== End Diagnostics ===" -ForegroundColor Cyan
```

## Common Solutions by Scenario

| Symptom | Solution |
|---------|----------|
| Ping fails | VPN not connected OR server is down |
| DNS fails | DNS server issue OR wrong server name |
| SMB test fails but ping works | Firewall blocking SMB (445/TCP) OR credentials |
| "Access denied" | Permission issue - contact IT |
| Works manually but not via policy | Group Policy issue - run `gpresult /r` |

## Contact IT If...

- Server is unreachable after VPN connection verified
- Authentication errors persist after ticket refresh
- Multiple users reporting same issue (server-side problem)
- Group Policy not applying (`gpresult /r` shows no drive mappings)

## Repository Context

This file server may be part of:
- **NativeBio infrastructure** (Proxmox 8 VE, REDCap, pfSense)
- **TDR infrastructure** (Proxmox 9 VE)
- **Missouri Breaks** (mbiri.net servers)
- **Iyeska HQ** (main servers)

Check `CLAUDE.md` → Infrastructure Context for network details.
