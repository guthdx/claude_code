# Transfer Setup to MacBook Pro M1 14

Quick guide for setting up Continue on your other MacBook Pro M1 14.

## Option 1: AirDrop (Fastest)

### On This Mac (Current):
1. Open Finder → Go to `~/terminal_projects/claude_code/code_iyeska_net/`
2. Select `setup-continue.sh`
3. Right-click → Share → AirDrop
4. Select your M1 MacBook Pro

### On M1 MacBook Pro:
1. Accept the AirDrop file (will save to Downloads)
2. Open Terminal
3. Run:
```bash
cd ~/Downloads
chmod +x setup-continue.sh
./setup-continue.sh
```

Done! The script will handle everything.

---

## Option 2: iCloud Drive

### On This Mac:
```bash
# Copy script to iCloud
cp ~/terminal_projects/claude_code/code_iyeska_net/setup-continue.sh ~/Library/Mobile\ Documents/com~apple~CloudDocs/
```

### On M1 MacBook Pro:
```bash
# Run from iCloud Drive
cd ~/Library/Mobile\ Documents/com~apple~CloudDocs/
chmod +x setup-continue.sh
./setup-continue.sh
```

---

## Option 3: Git Clone (If Using Git)

If this repo is pushed to GitHub/GitLab:

### On M1 MacBook Pro:
```bash
# Clone the repo
git clone YOUR_REPO_URL
cd YOUR_REPO/code_iyeska_net

# Run setup
./setup-continue.sh
```

---

## Option 4: Copy-Paste (Simple)

### On This Mac:
```bash
# Display the script
cat ~/terminal_projects/claude_code/code_iyeska_net/setup-continue.sh
```

### On M1 MacBook Pro:
1. Create the script:
```bash
nano ~/setup-continue.sh
```

2. Paste the script content
3. Press `Ctrl+X`, then `Y`, then `Enter` to save
4. Make executable and run:
```bash
chmod +x ~/setup-continue.sh
./setup-continue.sh
```

---

## Option 5: One-Line Remote Install

If you push this to GitHub, create a raw URL for the script:

```bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/code_iyeska_net/setup-continue.sh | bash
```

Replace `USERNAME` and `REPO` with your actual GitHub username and repository name.

---

## Option 6: SSH/SCP (If Macs Can Connect)

If both Macs are on the same network and have Remote Login enabled:

### On M1 MacBook Pro:
Enable Remote Login:
- System Settings → General → Sharing → Remote Login → ON

### On This Mac:
```bash
# Find M1's IP address first (on M1: System Settings → Network)
# Then copy script to M1
scp ~/terminal_projects/claude_code/code_iyeska_net/setup-continue.sh USERNAME@M1_IP_ADDRESS:~/

# SSH to M1 and run
ssh USERNAME@M1_IP_ADDRESS
chmod +x ~/setup-continue.sh
./setup-continue.sh
```

---

## Recommended Method

**For Quickest Setup: Use AirDrop (Option 1)**

It's the fastest and most reliable for transferring between your own Macs.

---

## After Setup on M1

Once the script completes on your M1:

1. ✅ Continue extension will be installed
2. ✅ Configuration will be set up
3. ✅ Connection to code.iyeska.net will be verified

Just reload VS Code and you're ready to go!

### Keyboard Shortcuts (same on both Macs):
- `Cmd+L` - Chat about selected code
- `Cmd+I` - Inline edit
- `/edit` - Modify selected code
- `/cmd` - Generate shell commands

---

## Verify It's Working

On the M1, after setup:

```bash
# Test connection
curl https://code.iyeska.net/api/tags

# Check config
cat ~/.continue/config.yaml

# List VS Code extensions
/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code --list-extensions | grep continue
```

All should show successful results!
