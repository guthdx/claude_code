# Continue Extension Setup for code.iyeska.net

Automated setup for Continue VS Code extension to use remote Ollama models on your Mac Mini via code.iyeska.net.

## Quick Start

On your MacBook Pro, run this one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/code_iyeska_net/setup-continue.sh | bash
```

Or if you have this repo cloned locally:

```bash
cd ~/terminal_projects/claude_code/code_iyeska_net
./setup-continue.sh
```

## What This Does

The setup script will automatically:

1. ✅ Check if VS Code is installed
2. ✅ Test connection to code.iyeska.net
3. ✅ Install Continue extension
4. ✅ Create configuration file with all remote models
5. ✅ Verify the setup works

## Prerequisites

- macOS with VS Code installed
- Network access to code.iyeska.net
- Mac Mini running with Ollama and tunnel/proxy active

## Available Models

After setup, you'll have access to these models:

| Model | Size | Roles |
|-------|------|-------|
| Qwen2.5-Coder 32B | 32.8B | Chat, Edit, Apply |
| Qwen2.5-Coder 14B | 14.8B | Chat, Edit, Apply |
| DeepSeek-R1 32B | 32.8B | Chat, Edit |
| DeepSeek-R1 14B | 14.8B | Chat, Edit |
| Llama 3.3 | 70.6B | Chat, Edit |
| Phi4 | 14.7B | Chat |
| DeepSeek-R1 7B | 7.6B | Chat |
| Qwen2.5-Coder 14B | 14.8B | Autocomplete |

## Manual Setup

If you prefer to set up manually:

### 1. Install Continue Extension

```bash
/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code --install-extension continue.continue
```

### 2. Create Config File

Create or edit `~/.continue/config.yaml`:

```yaml
name: Remote Ollama via code.iyeska.net
version: 1.0.0
schema: v1
models:
  - name: Qwen2.5-Coder 32B
    provider: ollama
    model: qwen2.5-coder:32b
    apiBase: https://code.iyeska.net
    roles:
      - chat
      - edit
      - apply
  # ... (see continue-config.yaml for full configuration)
```

### 3. Reload VS Code

Press `Cmd+Shift+P` → Type "Reload Window" → Press Enter

## Using Continue

### Keyboard Shortcuts

- `Cmd+L` - Chat about selected code
- `Cmd+I` - Inline edit
- `/edit` - Modify selected code
- `/cmd` - Generate shell commands

### Selecting Models

1. Click Continue icon in left sidebar
2. Look for model dropdown at top
3. Select your preferred model
4. Start chatting!

### Recommended Models

- **For coding**: Qwen2.5-Coder 32B (best quality)
- **For speed**: Qwen2.5-Coder 14B or DeepSeek-R1 14B
- **For reasoning**: DeepSeek-R1 32B (shows thinking process)
- **For quick tasks**: DeepSeek-R1 7B

## Troubleshooting

### Cannot connect to code.iyeska.net

1. Check if Mac Mini is awake and running
2. Verify Ollama is running: `ollama list`
3. Check tunnel/proxy status
4. Test connection: `curl https://code.iyeska.net/api/tags`

### VS Code not found

The script looks for VS Code at `/Applications/Visual Studio Code.app`. If installed elsewhere, you'll need to update the path.

### Continue extension not appearing

1. Reload VS Code: `Cmd+Shift+P` → "Reload Window"
2. Check if installed: View → Extensions → Search "Continue"
3. Restart VS Code completely

### Models not showing up

1. Check `~/.continue/config.yaml` exists and has correct format
2. Reload VS Code
3. Click Continue icon and look for model dropdown

## Configuration File Location

The Continue config is stored at:
```
~/.continue/config.yaml
```

To edit manually:
```bash
code ~/.continue/config.yaml
```

## Sharing This Setup

To set up on another machine:

1. Copy the `setup-continue.sh` script to the new machine
2. Make it executable: `chmod +x setup-continue.sh`
3. Run it: `./setup-continue.sh`

Or use the one-liner at the top of this README (requires script to be in a public repo).

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Verify Mac Mini and tunnel are running
3. Test connection with: `curl https://code.iyeska.net/api/tags`
4. Check VS Code extension logs: View → Output → Select "Continue"

## License

MIT
