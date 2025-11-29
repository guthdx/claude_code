# Quick Setup on Client Machines (M4, M1, Mac Mini)

**Time**: 5 minutes
**Method**: Git pull (no AirDrop needed!)

## On Each Client Machine

### Step 1: Clone or Pull Repository

**If you already have the repository:**
```bash
cd ~/terminal_projects/claude_code
git pull origin main
```

**If this is a new machine:**
```bash
mkdir -p ~/terminal_projects
cd ~/terminal_projects
git clone git@github.com:guthdx/claude_code.git
cd claude_code
```

### Step 2: Run Setup Script

```bash
./setup-memory-mcp-client.sh
```

The script will:
- ✓ Check NetBird VPN
- ✓ Test SSH to server
- ✓ Configure Claude Desktop/Code automatically
- ✓ Test connection

### Step 3: Restart Claude

**Claude Desktop:**
- Quit (Cmd+Q)
- Relaunch

**Claude Code:**
```bash
claude mcp list
# Should show "memory" server
```

### Step 4: Test

In Claude:
```
You: Remember that I prefer TypeScript over JavaScript
Claude: [stores memory]

You: What programming preferences do you remember?
Claude: [retrieves memory] You prefer TypeScript over JavaScript
```

## That's It!

Now try the same query on a different machine - Claude should remember across all machines!

## Troubleshooting

**NetBird not connected:**
```bash
netbird up
```

**SSH not working:**
```bash
ssh-copy-id guthdx@192.168.11.20
```

**Need more help:**
See `PHASE3_CLIENT_SETUP.md` for detailed troubleshooting.
