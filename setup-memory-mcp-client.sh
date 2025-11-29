#!/bin/bash
# Memory MCP Client Setup Script
# Part of Phase 3: Cross-Machine Memory Synchronization
#
# This script configures Claude Desktop or Claude Code to connect to the
# Memory MCP Server running on Ubuntu (192.168.11.20) via SSH over NetBird VPN.
#
# Prerequisites:
# - NetBird VPN connected
# - SSH access to guthdx@192.168.11.20 configured (passwordless with SSH keys)
# - Claude Desktop or Claude Code installed
#
# Usage:
#   ./setup-memory-mcp-client.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MCP_SERVER_HOST="192.168.11.20"
MCP_SERVER_USER="guthdx"
MCP_SERVER_PATH="/home/guthdx/mcp-memory"
CLAUDE_DESKTOP_CONFIG="$HOME/.claude.json"
CLAUDE_CODE_CONFIG="$HOME/terminal_projects/claude_code/.mcp.json"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Memory MCP Client Setup${NC}"
echo -e "${BLUE}Phase 3: Cross-Machine Sync${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}→${NC} $1"
}

# Detect OS
OS=$(uname -s)
if [[ "$OS" == "Darwin" ]]; then
    print_status "Detected macOS"
elif [[ "$OS" == "Linux" ]]; then
    print_status "Detected Linux"
else
    print_error "Unsupported OS: $OS"
    exit 1
fi

# Check if NetBird is running
print_info "Checking NetBird VPN connection..."
if command -v netbird &> /dev/null; then
    if netbird status | grep -q "Connected"; then
        print_status "NetBird VPN is connected"
    else
        print_warning "NetBird is installed but not connected"
        echo "Please connect to NetBird VPN and try again"
        echo "Run: netbird up"
        exit 1
    fi
else
    print_warning "NetBird not found in PATH"
    echo "Checking if NetBird is running anyway..."
    if ping -c 1 -W 1 $MCP_SERVER_HOST &> /dev/null; then
        print_status "Can reach $MCP_SERVER_HOST - assuming VPN is working"
    else
        print_error "Cannot reach $MCP_SERVER_HOST"
        echo "Please ensure NetBird VPN is connected"
        exit 1
    fi
fi

# Test SSH connection
print_info "Testing SSH connection to Memory MCP Server..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes ${MCP_SERVER_USER}@${MCP_SERVER_HOST} "echo 'SSH OK'" &> /dev/null; then
    print_status "SSH connection successful"
else
    print_error "Cannot connect via SSH to ${MCP_SERVER_USER}@${MCP_SERVER_HOST}"
    echo ""
    echo "Please set up SSH key authentication:"
    echo "  1. Generate SSH key (if needed): ssh-keygen -t ed25519"
    echo "  2. Copy to server: ssh-copy-id ${MCP_SERVER_USER}@${MCP_SERVER_HOST}"
    echo "  3. Test: ssh ${MCP_SERVER_USER}@${MCP_SERVER_HOST}"
    exit 1
fi

# Test Memory MCP Server availability
print_info "Checking Memory MCP Server availability..."
if ssh ${MCP_SERVER_USER}@${MCP_SERVER_HOST} "test -d ${MCP_SERVER_PATH}"; then
    print_status "Memory MCP Server found at ${MCP_SERVER_PATH}"
else
    print_error "Memory MCP Server not found at ${MCP_SERVER_PATH}"
    echo "Please ensure Phase 2 is complete on the Ubuntu server"
    exit 1
fi

# Detect Claude installation
CLAUDE_INSTALLED=false
CLAUDE_TYPE=""

if [[ "$OS" == "Darwin" ]]; then
    if [[ -d "/Applications/Claude.app" ]]; then
        CLAUDE_INSTALLED=true
        CLAUDE_TYPE="desktop"
        print_status "Claude Desktop found"
    fi
fi

if command -v claude &> /dev/null; then
    CLAUDE_INSTALLED=true
    if [[ "$CLAUDE_TYPE" == "desktop" ]]; then
        CLAUDE_TYPE="both"
    else
        CLAUDE_TYPE="code"
    fi
    print_status "Claude Code CLI found"
fi

if [[ "$CLAUDE_INSTALLED" == false ]]; then
    print_error "Neither Claude Desktop nor Claude Code found"
    echo "Please install Claude Desktop or Claude Code first"
    exit 1
fi

# Create MCP configuration
create_mcp_config() {
    local config_file=$1
    local config_type=$2

    print_info "Configuring $config_type..."

    # Backup existing config if it exists
    if [[ -f "$config_file" ]]; then
        backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$config_file" "$backup_file"
        print_warning "Backed up existing config to: $backup_file"
    fi

    # Check if config already has memory server
    if [[ -f "$config_file" ]] && grep -q '"memory"' "$config_file"; then
        print_warning "Memory MCP server already configured in $config_file"
        read -p "Overwrite existing configuration? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping $config_type configuration"
            return
        fi
    fi

    # Create directory if needed
    mkdir -p "$(dirname "$config_file")"

    # Read existing config or create new
    if [[ -f "$config_file" ]]; then
        # Parse existing JSON and add/update memory server
        python3 - "$config_file" <<'PYTHON_SCRIPT'
import sys
import json

config_file = sys.argv[1]

# Read existing config
with open(config_file, 'r') as f:
    try:
        config = json.load(f)
    except:
        config = {}

# Ensure mcpServers exists
if 'mcpServers' not in config:
    config['mcpServers'] = {}

# Add/update memory server
config['mcpServers']['memory'] = {
    "command": "ssh",
    "args": [
        "guthdx@192.168.11.20",
        "cd /home/guthdx/mcp-memory && npm start"
    ],
    "env": {}
}

# Write back
with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')

print("Configuration updated successfully")
PYTHON_SCRIPT

        if [[ $? -eq 0 ]]; then
            print_status "$config_type configuration updated"
        else
            print_error "Failed to update $config_type configuration"
            return 1
        fi
    else
        # Create new config file
        cat > "$config_file" <<'EOF'
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
EOF
        print_status "Created new $config_type configuration"
    fi
}

# Configure based on what's installed
if [[ "$CLAUDE_TYPE" == "desktop" ]] || [[ "$CLAUDE_TYPE" == "both" ]]; then
    create_mcp_config "$CLAUDE_DESKTOP_CONFIG" "Claude Desktop"
fi

if [[ "$CLAUDE_TYPE" == "code" ]] || [[ "$CLAUDE_TYPE" == "both" ]]; then
    create_mcp_config "$CLAUDE_CODE_CONFIG" "Claude Code"
fi

# Test the connection
print_info "Testing Memory MCP Server connection..."
test_result=$(ssh ${MCP_SERVER_USER}@${MCP_SERVER_HOST} "cd ${MCP_SERVER_PATH} && timeout 5 npm start 2>&1 <<< '{\"jsonrpc\":\"2.0\",\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{},\"clientInfo\":{\"name\":\"setup-test\",\"version\":\"1.0.0\"}},\"id\":1}' | grep -c '\"result\"'" || echo "0")

if [[ "$test_result" -gt 0 ]]; then
    print_status "Memory MCP Server is responding correctly"
else
    print_warning "Could not verify server response (may be normal on first run)"
    echo "Server might need to download embedding model on first use (~80MB)"
fi

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

echo "Next steps:"
echo ""

if [[ "$CLAUDE_TYPE" == "desktop" ]] || [[ "$CLAUDE_TYPE" == "both" ]]; then
    echo "1. Restart Claude Desktop:"
    echo "   - Quit completely (Cmd+Q on macOS)"
    echo "   - Relaunch Claude Desktop"
    echo ""
fi

if [[ "$CLAUDE_TYPE" == "code" ]] || [[ "$CLAUDE_TYPE" == "both" ]]; then
    echo "2. Verify Claude Code MCP servers:"
    echo "   claude mcp list"
    echo "   (Should show 'memory' server)"
    echo ""
fi

echo "3. Test memory storage:"
echo "   In Claude, try: 'Remember that I prefer dark mode'"
echo ""

echo "4. Test memory retrieval:"
echo "   In Claude, try: 'What preferences do you remember about me?'"
echo ""

echo -e "${BLUE}Configuration files:${NC}"
if [[ "$CLAUDE_TYPE" == "desktop" ]] || [[ "$CLAUDE_TYPE" == "both" ]]; then
    echo "  - Claude Desktop: $CLAUDE_DESKTOP_CONFIG"
fi
if [[ "$CLAUDE_TYPE" == "code" ]] || [[ "$CLAUDE_TYPE" == "both" ]]; then
    echo "  - Claude Code: $CLAUDE_CODE_CONFIG"
fi

echo ""
echo -e "${BLUE}Troubleshooting:${NC}"
echo "  - Check NetBird: netbird status"
echo "  - Test SSH: ssh ${MCP_SERVER_USER}@${MCP_SERVER_HOST}"
echo "  - View logs: ssh ${MCP_SERVER_USER}@${MCP_SERVER_HOST} 'tail -f ${MCP_SERVER_PATH}/memory-debug.log'"
echo ""

print_status "Memory MCP Client setup complete!"
