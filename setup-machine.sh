#!/bin/bash

# Claude Code Workspace - Automated Machine Setup
# Works on macOS and Linux (Ubuntu/Debian)
# Usage: curl -fsSL https://raw.githubusercontent.com/guthdx/claude_code/main/setup-machine.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Claude Code Workspace Setup${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    SHELL_RC="$HOME/.zshrc"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    # Check if user uses zsh or bash
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_RC="$HOME/.bashrc"
    fi
else
    echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Detected OS: $OS${NC}"
echo -e "${GREEN}✓ Shell config: $SHELL_RC${NC}"
echo ""

# Function to check command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check version requirement
check_version() {
    local cmd=$1
    local required=$2
    local current=$3

    if [ -z "$current" ]; then
        echo -e "${RED}✗ $cmd not found${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ $cmd: $current${NC}"
    return 0
}

echo -e "${BLUE}[1/7] Checking prerequisites...${NC}"

# Check Node.js
if command_exists node; then
    NODE_VERSION=$(node --version)
    check_version "Node.js" "v25.1.0" "$NODE_VERSION"
else
    echo -e "${RED}✗ Node.js not found${NC}"
    echo -e "${YELLOW}  Install from: https://nodejs.org/${NC}"
    if [[ "$OS" == "linux" ]]; then
        echo -e "${YELLOW}  Quick install: curl -fsSL https://deb.nodesource.com/setup_25.x | sudo -E bash - && sudo apt-get install -y nodejs${NC}"
    fi
    exit 1
fi

# Check Git
if command_exists git; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    check_version "Git" "2.50" "$GIT_VERSION"
else
    echo -e "${RED}✗ Git not found${NC}"
    exit 1
fi

# Check Claude Code
if command_exists claude; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "installed")
    check_version "Claude Code" "any" "$CLAUDE_VERSION"
else
    echo -e "${YELLOW}⚠ Claude Code not found${NC}"
    echo -e "${YELLOW}  Install from: https://claude.ai/code${NC}"
    read -p "Continue without Claude Code? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}[2/7] Checking SSH setup for GitHub...${NC}"

# Check SSH key
if [ -f "$HOME/.ssh/id_ed25519.pub" ] || [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    echo -e "${GREEN}✓ SSH key found${NC}"

    # Test GitHub connection
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✓ GitHub SSH authentication working${NC}"
    else
        echo -e "${YELLOW}⚠ SSH key exists but GitHub authentication failed${NC}"
        echo -e "${YELLOW}  Add your SSH key to GitHub: https://github.com/settings/keys${NC}"
        if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
            echo -e "${BLUE}  Your public key:${NC}"
            cat "$HOME/.ssh/id_ed25519.pub"
        fi
        read -p "Press Enter after adding SSH key to GitHub..."
    fi
else
    echo -e "${YELLOW}⚠ No SSH key found. Generating one...${NC}"
    read -p "Enter your email for SSH key: " EMAIL
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""

    echo -e "${BLUE}  Your public key (add to GitHub):${NC}"
    cat "$HOME/.ssh/id_ed25519.pub"
    echo ""
    echo -e "${YELLOW}  Go to: https://github.com/settings/keys${NC}"
    echo -e "${YELLOW}  Click 'New SSH key' and paste the key above${NC}"
    read -p "Press Enter after adding SSH key to GitHub..."
fi

echo ""
echo -e "${BLUE}[3/7] Setting up repository...${NC}"

# Determine clone location
CLONE_DIR="$HOME/terminal_projects/claude_code"

if [ -d "$CLONE_DIR" ]; then
    echo -e "${YELLOW}⚠ Directory already exists: $CLONE_DIR${NC}"
    read -p "Use existing directory? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter new location: " CLONE_DIR
        mkdir -p "$(dirname "$CLONE_DIR")"
    fi
else
    mkdir -p "$(dirname "$CLONE_DIR")"
fi

# Clone or update repository
if [ -d "$CLONE_DIR/.git" ]; then
    echo -e "${GREEN}✓ Repository already cloned${NC}"
    cd "$CLONE_DIR"

    # Check git remote URL for security
    REMOTE_URL=$(git remote get-url origin)
    if [[ "$REMOTE_URL" == *"ghp_"* ]] || [[ "$REMOTE_URL" == *"@"*"github.com"* ]] && [[ "$REMOTE_URL" == https://* ]]; then
        echo -e "${RED}⚠ SECURITY ISSUE: Token in git remote URL!${NC}"
        echo -e "${YELLOW}  Fixing: Switching to SSH...${NC}"
        git remote set-url origin git@github.com:guthdx/claude_code.git
        echo -e "${GREEN}✓ Fixed: Now using SSH${NC}"
    fi

    echo -e "${BLUE}  Pulling latest changes...${NC}"
    git pull origin main
else
    echo -e "${BLUE}  Cloning repository...${NC}"
    git clone git@github.com:guthdx/claude_code.git "$CLONE_DIR"
    cd "$CLONE_DIR"
    echo -e "${GREEN}✓ Repository cloned${NC}"
fi

echo ""
echo -e "${BLUE}[4/7] Setting up environment variables...${NC}"

# Check if env vars already exist
if grep -q "PERPLEXITY_API_KEY" "$SHELL_RC" 2>/dev/null; then
    echo -e "${GREEN}✓ Environment variables already configured in $SHELL_RC${NC}"
else
    echo -e "${YELLOW}⚠ Environment variables not found${NC}"
    echo ""
    echo -e "${BLUE}  Enter your API keys:${NC}"

    read -p "Perplexity API Key: " PERPLEXITY_KEY
    read -p "GitHub Token: " GITHUB_TOKEN

    echo "" >> "$SHELL_RC"
    echo "# Claude Code Workspace - Added by setup-machine.sh on $(date)" >> "$SHELL_RC"
    echo "export PERPLEXITY_API_KEY=\"$PERPLEXITY_KEY\"" >> "$SHELL_RC"
    echo "export GITHUB_TOKEN=\"$GITHUB_TOKEN\"" >> "$SHELL_RC"

    echo -e "${GREEN}✓ Environment variables added to $SHELL_RC${NC}"
fi

# Load environment variables for current session
if [ -f "$SHELL_RC" ]; then
    source "$SHELL_RC"
fi

echo ""
echo -e "${BLUE}[5/7] Checking Docker (optional)...${NC}"

if command_exists docker; then
    if docker ps >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Docker installed and running${NC}"
    else
        echo -e "${YELLOW}⚠ Docker installed but not running${NC}"
        if [[ "$OS" == "macos" ]]; then
            echo -e "${YELLOW}  Start Docker Desktop${NC}"
        else
            echo -e "${YELLOW}  Run: sudo systemctl start docker${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠ Docker not installed (optional)${NC}"
    if [[ "$OS" == "linux" ]]; then
        read -p "Install Docker now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
            sudo sh /tmp/get-docker.sh
            sudo usermod -aG docker $USER
            echo -e "${GREEN}✓ Docker installed (logout/login to use without sudo)${NC}"
        fi
    else
        echo -e "${YELLOW}  Install Docker Desktop from: https://www.docker.com/products/docker-desktop${NC}"
    fi
fi

echo ""
echo -e "${BLUE}[6/7] Verifying MCP configuration...${NC}"

if [ -f "$CLONE_DIR/.mcp.json" ]; then
    echo -e "${GREEN}✓ Project MCP config found (.mcp.json)${NC}"
else
    echo -e "${RED}✗ .mcp.json not found${NC}"
fi

echo ""
echo -e "${BLUE}[7/7] Setup complete!${NC}"
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  ✓ Setup Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo -e "${BLUE}1. Reload your shell:${NC}"
echo -e "   source $SHELL_RC"
echo ""
echo -e "${BLUE}2. Navigate to workspace:${NC}"
echo -e "   cd $CLONE_DIR"
echo ""
echo -e "${BLUE}3. Start Claude Code:${NC}"
echo -e "   claude"
echo ""
echo -e "${BLUE}4. In Claude Code, say:${NC}"
echo -e '   "I just ran the setup script. Please read CLAUDE.md and'
echo -e '   SESSION_STATE.md, then verify all 5 MCP servers are configured."'
echo ""
echo -e "${BLUE}5. Verify MCP servers:${NC}"
echo -e "   claude mcp list"
echo ""
echo -e "${YELLOW}Security Reminders:${NC}"
echo -e "  - Read SECURITY_WARNING.md for important security notes"
echo -e "  - Consider rotating the GitHub token after setup"
echo -e "  - Never commit ~/.zshrc or ~/.bashrc to git"
echo ""
echo -e "${GREEN}Setup completed successfully!${NC}"
echo ""
