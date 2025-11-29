# Phase 3: Client Machine Setup for Cross-Machine Memory Sync

**Status**: Ready for deployment
**Distribution**: Via Git (no AirDrop needed!)
**Estimated Time**: 5-10 minutes per machine

## Overview

This phase configures your client machines (M4 MacBook, M1 MacBook, Mac Mini) to connect to the Memory MCP Server running on Ubuntu (192.168.11.20) via SSH over NetBird VPN.

**Key Benefit**: All machines share the same memory - what Claude learns on one machine is available on all machines!

## Prerequisites

Each client machine needs:
- ✅ NetBird VPN installed and connected
- ✅ SSH access configured to guthdx@192.168.11.20 (with SSH keys)
- ✅ Claude Desktop or Claude Code installed
- ✅ Git access to this repository

## Quick Setup (Automated)

### Step 1: Pull Latest Changes

On each client machine:

```bash
cd ~/terminal_projects/claude_code
git pull origin main
```

This downloads:
- `setup-memory-mcp-client.sh` - Automated setup script
- `PHASE3_CLIENT_SETUP.md` - This file
- `PHASE2_COMPLETE.md` - Server documentation

### Step 2: Run Setup Script

```bash
cd ~/terminal_projects/claude_code
./setup-memory-mcp-client.sh
```

The script will:
1. ✓ Check NetBird VPN connection
2. ✓ Test SSH access to Ubuntu server
3. ✓ Verify Memory MCP Server is running
4. ✓ Detect Claude Desktop / Claude Code
5. ✓ Configure MCP settings automatically
6. ✓ Backup existing configs
7. ✓ Test server connection

### Step 3: Restart Claude

**Claude Desktop (macOS):**
- Quit completely: `Cmd+Q`
- Relaunch Claude Desktop

**Claude Code:**
```bash
# Just close and reopen your terminal, or:
claude mcp list
# Should show "memory" server
```

### Step 4: Test It Works

Open Claude and try:

**Store a memory:**
```
Remember that I prefer dark mode and use macOS.
```

**Retrieve memory:**
```
What preferences do you remember about me?
```

**Test on another machine:**
- Pull the same repository on your M1 MacBook
- Run the same setup script
- Ask Claude the same question
- It should remember what you told it on the M4!

## What Gets Configured

### Configuration File Locations

**Claude Desktop:** `~/.claude.json`
```json
{
  "mcpServers": {
    "memory": {
      "command": "ssh",
      "args": [
        "guthdx@192.168.11.20",
        "cd /home/guthdx/mcp-memory && npm start"
      ],
      "env": {}
    }
  }
}
```

**Claude Code:** `~/terminal_projects/claude_code/.mcp.json`
```json
{
  "mcpServers": {
    "memory": {
      "command": "ssh",
      "args": [
        "guthdx@192.168.11.20",
        "cd /home/guthdx/mcp-memory && npm start"
      ],
      "env": {}
    }
  }
}
```

### How It Works

```
Your Mac (anywhere)
       ↓
NetBird VPN (encrypted tunnel)
       ↓
SSH to 192.168.11.20
       ↓
Memory MCP Server (stdio)
       ↓
PostgreSQL + pgvector
```

**Key Points:**
- Works from anywhere (home, coffee shop, hotel)
- NetBird creates encrypted VPN tunnel over internet
- SSH provides secure transport for MCP stdio protocol
- No manual file syncing needed
- Real-time shared memory across all machines

## Manual Setup (If Needed)

If you prefer to configure manually or the script fails:

### 1. Check Prerequisites

```bash
# Check NetBird VPN
netbird status
# Should show: "Connected"

# Test SSH
ssh guthdx@192.168.11.20 echo "SSH works"
# Should print: "SSH works"

# Test Memory server
ssh guthdx@192.168.11.20 "cd /home/guthdx/mcp-memory && npm start -- --version"
```

### 2. Set Up SSH Keys (if needed)

```bash
# Generate key (if you don't have one)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy to Ubuntu server
ssh-copy-id guthdx@192.168.11.20

# Test passwordless login
ssh guthdx@192.168.11.20
```

### 3. Configure Claude Desktop

Edit `~/.claude.json`:

```json
{
  "mcpServers": {
    "memory": {
      "command": "ssh",
      "args": [
        "guthdx@192.168.11.20",
        "cd /home/guthdx/mcp-memory && npm start"
      ],
      "env": {}
    }
  }
}
```

### 4. Configure Claude Code

Edit `.mcp.json` in your project directory:

```json
{
  "mcpServers": {
    "memory": {
      "command": "ssh",
      "args": [
        "guthdx@192.168.11.20",
        "cd /home/guthdx/mcp-memory && npm start"
      ],
      "env": {}
    }
  }
}
```

## Verification

### Check MCP Server Is Loaded

**Claude Code:**
```bash
claude mcp list
```

Should show:
```
memory - Memory Server (1.0.0)
  Publisher: Iyeska LLC
  Tools: store_memory, search_memories, list_memories
```

**Claude Desktop:**
- Open Claude Desktop
- Look for memory tools in the tools panel
- Or ask Claude: "What MCP servers are available?"

### Test Memory Storage

```
You: Remember that my favorite color is blue.
Claude: [Uses store_memory tool] I'll remember that your favorite color is blue.
```

### Test Memory Retrieval

```
You: What's my favorite color?
Claude: [Uses search_memories tool] Your favorite color is blue.
```

### Test Cross-Machine Sync

1. **On M4 MacBook:**
   ```
   You: Remember I'm working on the Iyeska infrastructure project.
   ```

2. **On M1 MacBook** (different machine):
   ```
   You: What project am I working on?
   Claude: You're working on the Iyeska infrastructure project.
   ```

If this works, **cross-machine sync is working!** 🎉

## Troubleshooting

### "Cannot reach 192.168.11.20"

**Problem:** NetBird VPN not connected

**Solution:**
```bash
netbird up
netbird status
ping 192.168.11.20
```

### "SSH connection failed"

**Problem:** SSH keys not configured

**Solution:**
```bash
ssh-copy-id guthdx@192.168.11.20
ssh guthdx@192.168.11.20  # Test it works
```

### "Memory server not found"

**Problem:** Phase 2 not complete on Ubuntu server

**Solution:**
```bash
ssh guthdx@192.168.11.20
cd /home/guthdx/mcp-memory
npm start  # Test it starts
```

### "MCP server not showing up"

**Problem:** Claude Desktop/Code not restarted

**Solution:**
- **Desktop:** Completely quit (Cmd+Q) and relaunch
- **Code:** Close terminal and reopen

### "Tool call failed"

**Problem:** Server might be downloading embedding model (first run)

**Solution:**
Wait 1-2 minutes for model download, then try again. Check logs:
```bash
ssh guthdx@192.168.11.20 "tail -f /home/guthdx/mcp-memory/memory-debug.log"
```

### View Server Logs

```bash
# Real-time logs
ssh guthdx@192.168.11.20 "tail -f /home/guthdx/mcp-memory/memory-debug.log"

# Recent errors
ssh guthdx@192.168.11.20 "tail -100 /home/guthdx/mcp-memory/memory-debug.log | grep error"
```

## Git Workflow for Updates

When the server is updated or configs change:

```bash
# On Ubuntu server (after changes)
cd ~/terminal_projects/claude_code
git add .
git commit -m "Update Memory MCP configuration"
git push origin main

# On each client machine
cd ~/terminal_projects/claude_code
git pull origin main
./setup-memory-mcp-client.sh  # Re-run if configs changed
```

**No AirDrop needed!** All machines pull from the same git repository.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ M4 MacBook (Coffee Shop WiFi)                               │
│   Claude Desktop/Code → SSH via NetBird → Memory Server     │
└─────────────────────────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────┐
│ M1 MacBook (Hotel WiFi)                                     │
│   Claude Desktop/Code → SSH via NetBird → Memory Server     │
└─────────────────────────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────┐
│ Mac Mini (Home Network)                                     │
│   Claude Desktop/Code → SSH via NetBird → Memory Server     │
└─────────────────────────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────┐
│ Ubuntu Server (192.168.11.20)                               │
│                                                             │
│  Memory MCP Server (Node.js)                               │
│            ↓                                                │
│  PostgreSQL + pgvector                                     │
│  - Shared memory storage                                   │
│  - Semantic search with BERT                               │
│  - Real-time sync across all clients                       │
└─────────────────────────────────────────────────────────────┘
```

## Security Notes

### What's Encrypted
- ✅ NetBird VPN traffic (WireGuard encryption)
- ✅ SSH tunnel (end-to-end encrypted)
- ✅ Database connection (localhost only, no network exposure)

### Authentication
- ✅ NetBird authentication (to access VPN)
- ✅ SSH key authentication (to access server)
- ✅ PostgreSQL password (for database access)

### Best Practices
- Keep SSH keys secure (use passphrase)
- Don't commit SSH keys to git
- Rotate PostgreSQL password periodically
- Monitor server logs for unusual activity

## Performance Notes

### First Connection
- Initial model download: ~80MB (one time)
- Takes 30-60 seconds on first run
- Subsequent connections are instant

### Network Usage
- SSH connection: ~1-5 KB per memory operation
- Works well on mobile hotspot, hotel WiFi, etc.
- NetBird adds minimal overhead (<1ms typically)

### Memory Operations
- Store memory: ~100-300ms (embedding generation)
- Search memory: ~50-150ms (vector similarity search)
- List memories: ~10-50ms (simple query)

## Next Steps

Once all client machines are configured:

1. **Test basic memory:**
   - Store some preferences
   - Retrieve them on different machines
   - Verify sync works

2. **Use in real workflows:**
   - Let Claude remember your coding preferences
   - Store project context across sessions
   - Build up knowledge over time

3. **Monitor and maintain:**
   - Check logs occasionally
   - Watch for any sync issues
   - Update configs via git as needed

## Success Criteria

✅ All client machines configured
✅ Can store memories from any machine
✅ Can retrieve memories on any machine
✅ Semantic search works (similar queries find relevant memories)
✅ No manual file syncing needed

---

## Summary

**What This Achieves:**
- Shared memory across all your development machines
- Works from anywhere (home, travel, coffee shops)
- No AirDrop or manual file transfers
- Real-time synchronization via NetBird VPN
- Secure (encrypted VPN + SSH + passwordless keys)

**Maintenance:**
- Pull git updates when server changes
- Re-run setup script if needed
- All configuration managed through git

**Files in Repository:**
- `setup-memory-mcp-client.sh` - Automated setup script
- `PHASE3_CLIENT_SETUP.md` - This documentation
- `PHASE2_COMPLETE.md` - Server architecture docs
- `PHASE1_COMPLETE.md` - Database setup docs

Ready to set up your first client machine? Just `git pull` and run the script!
