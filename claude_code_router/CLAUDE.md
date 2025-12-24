# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**Claude Code Router (CCR)** is a request routing and transformation layer that sits between Claude Code and various LLM providers. It enables:

- Routing Claude Code requests to different models based on task type
- Supporting multiple providers (OpenRouter, DeepSeek, Ollama, Gemini, LM Studio, etc.)
- Transforming requests/responses to work with any provider's API format
- Dynamic model switching and custom routing logic

## Architecture

### Request Flow

```
Claude Code Client
        ↓
    CCR Server (localhost:3456)
        ↓
    Config Parser (JSON5 + env vars)
        ↓
    Router Decision (default/background/think/longContext/webSearch/image)
        ↓
    Transformer Pipeline (global → model-specific → custom)
        ↓
    Provider API Call
        ↓
    Response Transform & Return
```

### Core Components

1. **Server** - Fastify-based HTTP server on port 3456
2. **Configuration System** - `~/.ccr/config.json` (JSON5 format)
3. **Router** - Directs requests based on task type or custom logic
4. **Transformer Pipeline** - Adapts requests/responses for each provider
5. **Provider Manager** - Handles API calls to configured providers

## Configuration

### Location
- Main config: `~/.ccr/config.json`
- Auto-backups: `~/.ccr/config.json.*.bak` (keeps last 3)
- Logs: `~/.ccr/logs/`
- PID file: `~/.ccr/.claude-code-router.pid`

### Structure

```json
{
  "PORT": 3456,
  "HOST": "127.0.0.1",
  "LOG_LEVEL": "info",
  "API_TIMEOUT_MS": 600000,

  "Providers": [
    {
      "name": "provider-name",
      "api_base_url": "https://api.example.com/v1/chat/completions",
      "api_key": "$ENV_VAR_NAME",
      "models": ["model-1", "model-2"],
      "transformer": {
        "use": ["transformer-name"],
        "model-specific": {
          "use": ["another-transformer"]
        }
      }
    }
  ],

  "Router": {
    "default": "provider,model",
    "background": "provider,model",
    "think": "provider,model",
    "longContext": "provider,model",
    "longContextThreshold": 60000,
    "webSearch": "provider,model",
    "image": "provider,model"
  },

  "CUSTOM_ROUTER_PATH": "~/.ccr/custom-router.js"
}
```

### Environment Variables

Use `$VAR` or `${VAR}` syntax in config:

```json
{
  "api_key": "$OPENAI_API_KEY"
}
```

Set in `~/.zshrc`:
```bash
export OPENAI_API_KEY="sk-..."
```

## Router System

Routes requests to different models based on task type:

- **default** - General tasks
- **background** - Lightweight/cheaper models for background work
- **think** - Reasoning-heavy tasks (Plan Mode)
- **longContext** - Requests >60K tokens (threshold configurable)
- **webSearch** - Web search-enabled models
- **image** - Image processing (beta)

### Dynamic Model Switching

In Claude Code, use:
```
/model provider,model-name
```

### Custom Router

Create `~/.ccr/custom-router.js`:

```javascript
module.exports = async function router(req, config) {
  const userMessage = req.body.messages
    .find((m) => m.role === "user")?.content;

  if (userMessage?.includes("keyword")) {
    return "provider,model";
  }

  return null; // Fallback to default router
};
```

## Transformer System

Transformers adapt requests/responses between Claude Code format and provider APIs.

### Built-in Transformers

- `anthropic` - Pass-through (no transformation)
- `deepseek` - DeepSeek API compatibility
- `gemini` - Google Gemini API compatibility
- `openrouter` - OpenRouter routing + provider preferences
- `groq` - Groq API compatibility
- `maxtoken` - Set max_tokens parameter
- `tooluse` - Optimize tool usage via tool_choice
- `reasoning` - Handle reasoning_content field
- `sampling` - Manage temperature, top_p, top_k, repetition_penalty
- `enhancetool` - Add error tolerance to tool calls
- `cleancache` - Clear cache_control fields
- `vertex-gemini` - Vertex AI Gemini authentication

### Transformer Application

**Global (all models):**
```json
"transformer": {
  "use": ["deepseek"]
}
```

**Model-specific:**
```json
"transformer": {
  "use": ["deepseek"],
  "deepseek-chat": {
    "use": ["tooluse"]
  }
}
```

**With options:**
```json
"transformer": {
  "use": [
    ["maxtoken", { "max_tokens": 16384 }]
  ]
}
```

### Custom Transformers (Plugins)

```json
{
  "transformers": [
    {
      "path": "~/.ccr/plugins/custom-transformer.js",
      "options": { "key": "value" }
    }
  ]
}
```

## Common Commands

### Server Management

```bash
ccr start          # Start router server
ccr stop           # Stop server
ccr restart        # Restart server
ccr status         # Check server status
ccr logs           # View server logs
```

### Model Management

```bash
ccr model          # Interactive model selection/configuration
ccr code           # Start Claude Code with router
ccr ui             # Open web UI for config management
```

### Environment Setup

```bash
eval "$(ccr activate)"   # Set environment variables for current shell
```

Add to `~/.zshrc` for persistence:
```bash
# Claude Code Router
alias ccr='npx --prefix ~/path/to/installation ccr'
eval "$(ccr activate 2>/dev/null)"
```

## Configuration Examples

### LM Studio (Local)

```json
{
  "name": "lmstudio",
  "api_base_url": "http://localhost:1234/v1/chat/completions",
  "api_key": "lm-studio",
  "models": ["qwen/qwen3-coder-30b"]
}
```

### Ollama (Local)

```json
{
  "name": "ollama",
  "api_base_url": "http://localhost:11434/v1/chat/completions",
  "api_key": "ollama",
  "models": ["qwen2.5-coder:latest"]
}
```

### DeepSeek with Tooluse

```json
{
  "name": "deepseek",
  "api_base_url": "https://api.deepseek.com/chat/completions",
  "api_key": "$DEEPSEEK_API_KEY",
  "models": ["deepseek-chat", "deepseek-reasoner"],
  "transformer": {
    "use": ["deepseek"],
    "deepseek-chat": {
      "use": ["tooluse"]
    }
  }
}
```

### OpenRouter with Provider Routing

```json
{
  "name": "openrouter",
  "api_base_url": "https://openrouter.ai/api/v1/chat/completions",
  "api_key": "$OPENROUTER_API_KEY",
  "models": ["google/gemini-2.5-pro-preview"],
  "transformer": {
    "use": [
      ["openrouter", {
        "provider": { "only": ["google"] }
      }]
    ]
  }
}
```

### Multi-Provider Routing

```json
{
  "Router": {
    "default": "deepseek,deepseek-chat",
    "background": "ollama,qwen2.5-coder:latest",
    "think": "deepseek,deepseek-reasoner",
    "longContext": "openrouter,google/gemini-2.5-pro-preview",
    "webSearch": "gemini,gemini-2.5-flash"
  }
}
```

## GitHub Actions Integration

For CI/CD environments, set `NON_INTERACTIVE_MODE: true` in config:

```yaml
- name: Setup CCR Config
  run: |
    mkdir -p $HOME/.ccr
    cat << 'EOF' > $HOME/.ccr/config.json
    {
      "NON_INTERACTIVE_MODE": true,
      "Providers": [
        {
          "name": "deepseek",
          "api_base_url": "https://api.deepseek.com/chat/completions",
          "api_key": "${{ secrets.DEEPSEEK_API_KEY }}",
          "models": ["deepseek-chat"]
        }
      ],
      "Router": {
        "default": "deepseek,deepseek-chat"
      }
    }
    EOF

- name: Start CCR
  run: npx @musistudio/claude-code-router start

- name: Run Claude Code
  uses: anthropics/claude-code-action@beta
  env:
    ANTHROPIC_BASE_URL: http://localhost:3456
```

## Logging

Two separate log systems:

1. **Server logs**: `~/.ccr/logs/ccr-*.log`
   - HTTP requests, API calls, server events
   - Auto-rotates (keeps 9 most recent)

2. **Application log**: `~/.ccr/claude-code-router.log`
   - Routing decisions, business logic

Control via `LOG_LEVEL`: `fatal`, `error`, `warn`, `info`, `debug`, `trace`

## Troubleshooting

**Server won't start:**
```bash
ccr stop
rm ~/.ccr/.claude-code-router.pid
ccr start
```

**Config parsing errors:**
- Validate JSON5 syntax (supports comments, trailing commas)
- Verify environment variable names
- Use `ccr ui` to validate config

**Transformer not working:**
- Check transformer name spelling
- Verify provider supports the transformer
- Review logs: `ccr logs`

**Test router connection:**
```bash
curl -s http://127.0.0.1:3456/health
```

## Key Dependencies

- **Fastify** (5.4.0) - Web server framework
- **Tiktoken** (1.0.21) - Token counting for routing
- **@musistudio/llms** (1.0.46) - LLM provider SDK
- **json5** (2.2.3) - JSON5 parsing (comments support)

## File Locations

```
~/terminal_projects/claude_code/claude_code_router/
├── package.json              # Project metadata
├── node_modules/
│   └── @musistudio/claude-code-router/  # Actual implementation
└── test_request.json         # Test payload

~/.ccr/
├── config.json               # Main configuration
├── config.json.*.bak         # Auto-backups (last 3)
├── .claude-code-router.pid   # Process ID
├── logs/                     # Server logs
│   └── ccr-*.log
└── plugins/                  # Custom transformers
    └── custom-router.js
```

## Security

1. **API Keys** - Use environment variable interpolation
2. **Host Binding** - Defaults to 127.0.0.1 (localhost only)
3. **Authentication** - Set `APIKEY` in config to require Bearer tokens
4. **Proxy Support** - Use `PROXY_URL` for corporate environments
