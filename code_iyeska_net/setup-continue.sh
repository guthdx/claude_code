#!/bin/bash

###############################################################################
# Continue Extension Setup Script for code.iyeska.net Remote Ollama
#
# This script automates the installation and configuration of Continue
# extension to use remote Ollama models on code.iyeska.net
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

print_step() {
    echo -e "\n${BLUE}▶${NC} $1"
}

# Check if VS Code is installed
check_vscode() {
    print_step "Checking for VS Code installation..."

    if [ -d "/Applications/Visual Studio Code.app" ]; then
        print_success "VS Code is installed"
        VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
        return 0
    else
        print_error "VS Code not found in /Applications/"
        print_info "Please install VS Code from https://code.visualstudio.com/"
        exit 1
    fi
}

# Test connection to code.iyeska.net
test_connection() {
    print_step "Testing connection to code.iyeska.net..."

    if curl -s --max-time 5 https://code.iyeska.net/api/tags > /dev/null 2>&1; then
        print_success "Connection to code.iyeska.net successful"

        # Count available models
        MODEL_COUNT=$(curl -s https://code.iyeska.net/api/tags | grep -o '"name"' | wc -l | xargs)
        print_info "Found $MODEL_COUNT models available"
        return 0
    else
        print_error "Cannot connect to code.iyeska.net"
        print_info "Please ensure:"
        print_info "  1. Your Mac Mini is running"
        print_info "  2. Ollama is running on the Mac Mini"
        print_info "  3. The tunnel/proxy is active"
        exit 1
    fi
}

# Install Continue extension
install_continue() {
    print_step "Installing Continue extension..."

    # Check if already installed
    if "$VSCODE_BIN" --list-extensions | grep -q "continue.continue"; then
        print_info "Continue extension is already installed"
        CURRENT_VERSION=$("$VSCODE_BIN" --list-extensions --show-versions | grep continue.continue | cut -d'@' -f2)
        print_info "Current version: $CURRENT_VERSION"
    else
        print_info "Installing Continue extension..."
        "$VSCODE_BIN" --install-extension continue.continue
        print_success "Continue extension installed successfully"
    fi
}

# Create Continue configuration
create_config() {
    print_step "Creating Continue configuration..."

    # Create .continue directory if it doesn't exist
    mkdir -p ~/.continue

    # Backup existing config if present
    if [ -f ~/.continue/config.yaml ]; then
        BACKUP_FILE=~/.continue/config.yaml.backup.$(date +%Y%m%d_%H%M%S)
        cp ~/.continue/config.yaml "$BACKUP_FILE"
        print_info "Backed up existing config to $BACKUP_FILE"
    fi

    # Create new config
    cat > ~/.continue/config.yaml << 'EOF'
name: Remote Ollama via code.iyeska.net
version: 1.0.0
schema: v1
models:
  - name: Qwen2.5-Coder 32B
    provider: ollama
    model: qwen2.5-coder:32b
    apiBase: https://code.iyeska.net
    contextLength: 32768
    completionOptions:
      num_ctx: 32768
      temperature: 0.2
      num_predict: 2048
    roles:
      - chat
      - edit
      - apply
  - name: Qwen2.5-Coder 14B
    provider: ollama
    model: qwen2.5-coder:14b
    apiBase: https://code.iyeska.net
    contextLength: 32768
    completionOptions:
      num_ctx: 32768
      temperature: 0.2
      num_predict: 2048
    roles:
      - chat
      - edit
      - apply
  - name: DeepSeek-R1 32B
    provider: ollama
    model: deepseek-r1:32b
    apiBase: https://code.iyeska.net
    contextLength: 32768
    completionOptions:
      num_ctx: 32768
      temperature: 0.3
      num_predict: 4096
    roles:
      - chat
      - edit
  - name: DeepSeek-R1 14B
    provider: ollama
    model: deepseek-r1:14b
    apiBase: https://code.iyeska.net
    contextLength: 32768
    completionOptions:
      num_ctx: 32768
      temperature: 0.3
      num_predict: 4096
    roles:
      - chat
      - edit
  - name: Llama 3.3
    provider: ollama
    model: llama3.3:latest
    apiBase: https://code.iyeska.net
    contextLength: 131072
    completionOptions:
      num_ctx: 32768
      temperature: 0.3
      num_predict: 2048
    roles:
      - chat
      - edit
  - name: Phi4
    provider: ollama
    model: phi4:latest
    apiBase: https://code.iyeska.net
    contextLength: 16384
    completionOptions:
      num_ctx: 16384
      temperature: 0.3
      num_predict: 2048
    roles:
      - chat
  - name: DeepSeek-R1 7B
    provider: ollama
    model: deepseek-r1:latest
    apiBase: https://code.iyeska.net
    contextLength: 32768
    completionOptions:
      num_ctx: 32768
      temperature: 0.3
      num_predict: 2048
    roles:
      - chat
  - name: Qwen2.5-Coder 14B Autocomplete
    provider: ollama
    model: qwen2.5-coder:14b
    apiBase: https://code.iyeska.net
    contextLength: 32768
    completionOptions:
      num_ctx: 8192
      temperature: 0.2
      num_predict: 128
    roles:
      - autocomplete
EOF

    print_success "Configuration file created at ~/.continue/config.yaml"
}

# Verify setup
verify_setup() {
    print_step "Verifying setup..."

    # Test a quick generation
    print_info "Testing model generation (this may take a few seconds)..."

    RESPONSE=$(curl -s --max-time 30 https://code.iyeska.net/api/generate \
        -d '{"model":"deepseek-r1:latest","prompt":"Reply with just OK","stream":false}' \
        -H "Content-Type: application/json" 2>&1)

    if echo "$RESPONSE" | grep -q '"done":true'; then
        print_success "Model generation test successful"
    else
        print_error "Model generation test failed"
        print_info "The extension is installed but there may be connectivity issues"
    fi
}

# Main installation flow
main() {
    print_header "Continue Extension Setup for code.iyeska.net"

    check_vscode
    test_connection
    install_continue
    create_config
    verify_setup

    print_header "Setup Complete!"

    echo -e "${GREEN}✓${NC} Continue extension is installed and configured"
    echo -e "${GREEN}✓${NC} Connected to code.iyeska.net with remote Ollama models"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Reload VS Code (Cmd+Shift+P → 'Reload Window')"
    echo "  2. Click the Continue icon in the left sidebar"
    echo "  3. Select a model from the dropdown"
    echo "  4. Start coding with AI assistance!"
    echo ""
    echo -e "${YELLOW}Keyboard Shortcuts:${NC}"
    echo "  • Cmd+L - Chat about selected code"
    echo "  • Cmd+I - Inline edit"
    echo "  • /edit - Modify selected code"
    echo "  • /cmd - Generate shell commands"
    echo ""
    print_success "Happy coding! 🚀"
}

# Run main function
main
