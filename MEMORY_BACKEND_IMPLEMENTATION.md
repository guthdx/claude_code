# Memory MCP Shared Backend Implementation Guide

**Generated**: 2025-11-27 by Tier 3 Agent
**Purpose**: Enable persistent, shared memory across all development machines
**Estimated Effort**: 4-6 hours (intermediate complexity)
**Recommended Solution**: PostgreSQL + pgvector

---

## Executive Summary

This guide provides step-by-step instructions for implementing a shared Memory MCP backend using PostgreSQL with the pgvector extension. This solution leverages your existing NetBird infrastructure and provides semantic search capabilities while maintaining data sovereignty principles.

**Key Benefits**:
- ✅ Semantic search with BERT embeddings (384 dimensions)
- ✅ Knowledge graph shared across all machines
- ✅ Leverages existing PostgreSQL database (NetBird)
- ✅ Self-hosted on your infrastructure
- ✅ Encrypted access over NetBird VPN
- ✅ $0 additional cost

---

## 1. Current Memory MCP Architecture

The default `@modelcontextprotocol/server-memory` uses **JSONL file-based storage**:

- **Storage Format**: JSON Lines (one JSON object per line)
- **Data Structure**: Knowledge graph with entities, relations, and observations
- **Location**: Local filesystem (configurable via `MEMORY_FILE_PATH`)
- **Limitation**: No abstraction layer - tightly coupled to filesystem I/O
- **Multi-machine Issue**: Each machine maintains separate local storage

---

## 2. Backend Options Comparison

### Option A: PostgreSQL + pgvector ⭐ RECOMMENDED

**Pros**:
- Already running on infrastructure (NetBird PostgreSQL at 192.168.11.20)
- Native JSONB support for flexible entity storage
- pgvector extension enables semantic search
- Battle-tested reliability and ACID compliance
- Existing implementation available (sdimitrov/mcp-memory)
- Free and open-source

**Cons**:
- Slightly higher resource usage than SQLite
- Requires pgvector extension setup

**Best For**: Production use, multi-machine sync, semantic search

### Option B: Redis + RedisGraph

**Pros**:
- Extremely fast in-memory operations
- Native graph database support
- Vector embeddings support (Redis Stack)

**Cons**:
- Requires new service deployment
- Higher memory usage (all data in RAM)
- Additional infrastructure complexity

**Best For**: High-frequency access patterns, real-time applications

### Option C: Qdrant Vector Database

**Pros**:
- Purpose-built for vector similarity search
- Excellent for AI/ML workloads

**Cons**:
- Overkill for simple knowledge graph storage
- New service to maintain
- Better suited for pure vector search use cases

**Best For**: Advanced vector search, RAG applications

### Option D: SQLite on Shared Storage

**Pros**:
- Simplest database option
- No server required

**Cons**:
- File locking issues with concurrent writes
- Poor performance over network filesystems
- Not designed for multi-client access

**Best For**: Single-machine use only ❌

---

## 3. Recommended Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Iyeska Infrastructure                        │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐         NetBird VPN          ┌──────────────────┐
│   Mac Mini       │◄──────────────────────────────►│  MacBook Pro    │
│   (Main Dev)     │         (Encrypted)           │  (Remote Work)   │
│                  │                                │                  │
│  Claude Desktop  │                                │  Claude Desktop  │
│       ↓          │                                │       ↓          │
│  Memory MCP      │                                │  Memory MCP      │
│   Client         │                                │   Client         │
└──────────────────┘                                └──────────────────┘
        │                                                    │
        │                  HTTPS (PostgreSQL Protocol)       │
        │                  Port 5432 over NetBird VPN        │
        └────────────────────────┬──────────────────────────┘
                                 ↓
                    ┌─────────────────────────────┐
                    │  Ubuntu Server              │
                    │  192.168.11.20              │
                    │                             │
                    │  ┌───────────────────────┐  │
                    │  │ Memory MCP Server     │  │
                    │  │ (Node.js + Express)   │  │
                    │  │ Port: 3333            │  │
                    │  │                       │  │
                    │  │ - RESTful API         │  │
                    │  │ - BERT embeddings     │  │
                    │  │ - SSE for real-time   │  │
                    │  └───────────┬───────────┘  │
                    │              ↓               │
                    │  ┌───────────────────────┐  │
                    │  │ PostgreSQL 14+        │  │
                    │  │ (NetBird zdb)         │  │
                    │  │                       │  │
                    │  │ - Database: mcp_mem   │  │
                    │  │ - pgvector extension  │  │
                    │  │ - JSONB storage       │  │
                    │  │ - Vector indexes      │  │
                    │  └───────────────────────┘  │
                    └─────────────────────────────┘
```

### Database Schema

```sql
-- Main memory table
CREATE TABLE memories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type VARCHAR(50) NOT NULL,           -- 'learning', 'experience', 'preference'
  content JSONB NOT NULL,              -- Flexible entity data
  source VARCHAR(100),                 -- Where memory came from
  embedding vector(384),               -- pgvector semantic search
  tags TEXT[],                         -- Array of tags
  confidence FLOAT CHECK (confidence >= 0 AND confidence <= 1),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_memories_type ON memories(type);
CREATE INDEX idx_memories_tags ON memories USING GIN(tags);
CREATE INDEX idx_memories_content ON memories USING GIN(content);
CREATE INDEX idx_memories_embedding ON memories USING ivfflat(embedding vector_cosine_ops);
```

---

## 4. Implementation Steps

### Phase 1: Database Setup (30 minutes)

#### Step 1.1: Access NetBird PostgreSQL Container

```bash
# SSH to Ubuntu server
ssh user@192.168.11.20

# Access PostgreSQL container
cd ~/netbird
docker exec -it netbird-zdb-1 psql -U postgres
```

#### Step 1.2: Create Memory Database

```sql
-- Create dedicated database for Memory MCP
CREATE DATABASE mcp_memory;

-- Connect to new database
\c mcp_memory

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Verify extension
SELECT * FROM pg_extension WHERE extname = 'vector';

-- Create database user for Memory MCP
CREATE USER mcp_user WITH PASSWORD 'GENERATE_STRONG_PASSWORD_HERE';

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE mcp_memory TO mcp_user;
GRANT ALL ON SCHEMA public TO mcp_user;

-- Exit
\q
```

#### Step 1.3: Test Database Connection

```bash
# From Ubuntu server, test connection
docker exec -it netbird-zdb-1 psql -U mcp_user -d mcp_memory -c "SELECT version();"
```

---

### Phase 2: Memory MCP Server Installation (1-2 hours)

#### Step 2.1: Clone and Setup Server

```bash
# On Ubuntu server (192.168.11.20)
cd ~
git clone https://github.com/sdimitrov/mcp-memory.git
cd mcp-memory

# Install dependencies (requires Node.js 16+)
npm install
```

#### Step 2.2: Configure Environment

```bash
# Create .env file
cat > .env << 'EOF'
# Database connection
DATABASE_URL="postgresql://mcp_user:YOUR_PASSWORD_HERE@localhost:5432/mcp_memory"

# Server port
PORT=3333

# Optional: Enable debug logging
LOG_LEVEL=info
EOF
```

#### Step 2.3: Initialize Database Schema

```bash
# Run Prisma migrations to create tables
npm run prisma:migrate

# Verify schema
npm run prisma:studio  # Opens web UI on port 5555
```

#### Step 2.4: Start Server

```bash
# Development mode
npm run dev

# Production mode
npm start

# Or run as Docker container (recommended)
docker build -t mcp-memory:latest .
docker run -d \
  --name mcp-memory \
  --restart unless-stopped \
  -p 3333:3333 \
  -e DATABASE_URL="postgresql://mcp_user:PASSWORD@host.docker.internal:5432/mcp_memory" \
  mcp-memory:latest
```

#### Step 2.5: Create systemd Service (Production)

```bash
# Create service file
sudo nano /etc/systemd/system/mcp-memory.service
```

```ini
[Unit]
Description=Memory MCP Server
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=your_username
WorkingDirectory=/home/your_username/mcp-memory
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
Environment="NODE_ENV=production"

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable mcp-memory
sudo systemctl start mcp-memory

# Check status
sudo systemctl status mcp-memory
```

---

### Phase 3: Network & Security Configuration (1 hour)

#### Step 3.1: Configure Firewall

```bash
# Allow MCP Memory server port (internal only - no WAN exposure)
sudo ufw allow from 192.168.11.0/24 to any port 3333 comment 'Memory MCP Server'

# Verify
sudo ufw status numbered
```

#### Step 3.2: Setup DNS (Optional)

Add DNS record in Cloudflare (internal use only):

```
Type: A
Name: memory.iyeska.net
Value: 192.168.11.20
Proxy: DNS Only (gray cloud)
```

Or add to `/etc/hosts` on each client machine:

```bash
# Add to /etc/hosts on Mac Mini and MacBook Pro
sudo nano /etc/hosts

# Add this line:
192.168.11.20    memory.iyeska.net
```

#### Step 3.3: Test Connectivity

```bash
# From MacBook Pro connected to NetBird
curl -I http://192.168.11.20:3333/mcp/v1/health

# Expected: HTTP/1.1 200 OK
```

---

### Phase 4: Client Configuration (30 minutes per machine)

#### Step 4.1: Create MCP Client Wrapper

Since the sdimitrov/mcp-memory server uses a REST API (not standard MCP protocol), create a wrapper:

```bash
# Create wrapper project
mkdir -p ~/mcp-memory-client
cd ~/mcp-memory-client
npm init -y
npm install @modelcontextprotocol/sdk axios
```

Create `index.js`:

```javascript
#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import axios from 'axios';

const API_URL = process.env.MEMORY_API_URL || 'http://localhost:3333/mcp/v1';

const server = new Server({
  name: 'memory-api-client',
  version: '1.0.0',
}, {
  capabilities: {
    tools: {},
  },
});

// Implement MCP tools that call REST API
server.setRequestHandler('tools/list', async () => ({
  tools: [
    {
      name: 'create_memory',
      description: 'Store a new memory',
      inputSchema: {
        type: 'object',
        properties: {
          type: { type: 'string' },
          content: { type: 'object' },
          source: { type: 'string' },
          tags: { type: 'array', items: { type: 'string' } },
          confidence: { type: 'number' }
        },
        required: ['type', 'content']
      }
    },
    {
      name: 'search_memories',
      description: 'Search memories using semantic search',
      inputSchema: {
        type: 'object',
        properties: {
          query: { type: 'string' },
          type: { type: 'string' },
          tags: { type: 'array', items: { type: 'string' } }
        },
        required: ['query']
      }
    }
  ]
}));

server.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request.params;

  try {
    if (name === 'create_memory') {
      const response = await axios.post(`${API_URL}/memory`, args);
      return { content: [{ type: 'text', text: JSON.stringify(response.data) }] };
    } else if (name === 'search_memories') {
      const response = await axios.get(`${API_URL}/memory/search`, { params: args });
      return { content: [{ type: 'text', text: JSON.stringify(response.data) }] };
    }
  } catch (error) {
    return {
      content: [{ type: 'text', text: `Error: ${error.message}` }],
      isError: true
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Memory API MCP client running on stdio');
}

main().catch(console.error);
```

Update `package.json`:

```json
{
  "type": "module",
  "bin": {
    "mcp-memory-client": "./index.js"
  }
}
```

Install globally:

```bash
chmod +x index.js
npm link
```

#### Step 4.2: Update Claude Desktop Config

Edit `~/.claude.json` or `.mcp.json`:

```json
{
  "mcpServers": {
    "memory": {
      "command": "mcp-memory-client",
      "env": {
        "MEMORY_API_URL": "http://192.168.11.20:3333/mcp/v1"
      }
    }
  }
}
```

#### Step 4.3: Restart Claude Desktop

```bash
# Completely quit Claude Desktop (Cmd+Q on macOS)
# Then relaunch

# Verify MCP server is connected
claude mcp list
```

---

### Phase 5: Testing & Verification (30 minutes)

#### Step 5.1: API Health Check

```bash
# Test from each client machine
curl http://192.168.11.20:3333/mcp/v1/health

# Expected response:
{"status":"ok","timestamp":"2025-11-27T..."}
```

#### Step 5.2: Test Memory Creation

```bash
# Create test memory
curl -X POST http://192.168.11.20:3333/mcp/v1/memory \
  -H "Content-Type: application/json" \
  -d '{
    "type": "learning",
    "content": {
      "topic": "Memory MCP Setup",
      "details": "Successfully configured shared PostgreSQL backend"
    },
    "source": "setup-testing",
    "tags": ["infrastructure", "mcp", "postgresql"],
    "confidence": 0.95
  }'
```

#### Step 5.3: Test Semantic Search

```bash
# Search memories
curl "http://192.168.11.20:3333/mcp/v1/memory/search?query=database%20setup&type=learning"
```

#### Step 5.4: Test Multi-Machine Sync

1. **On Mac Mini**: Create a memory via Claude Desktop
2. **On MacBook Pro**: Search for that memory via Claude Desktop
3. **Verify**: Both machines see the same data

---

## 5. Security & Access Control

### Authentication Strategy

**Current Setup**: No authentication (internal network only)

**Recommended**: API Key Authentication

```javascript
// In server code, add middleware
const authenticate = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  if (!apiKey || apiKey !== process.env.API_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
};

app.use('/mcp/v1', authenticate);
```

Client configuration:

```json
{
  "mcpServers": {
    "memory": {
      "command": "mcp-memory-client",
      "env": {
        "MEMORY_API_URL": "http://192.168.11.20:3333/mcp/v1",
        "API_KEY": "your-secret-key-here"
      }
    }
  }
}
```

### Network Security

- Server only accessible on LAN (192.168.11.x)
- UFW firewall restricts access to local subnet
- NetBird VPN encrypts all traffic (WireGuard)
- No public internet exposure

### Backup Strategy

```bash
# Automated daily backups
crontab -e

# Add this line (daily at 2 AM)
0 2 * * * docker exec netbird-zdb-1 pg_dump -U mcp_user mcp_memory | gzip > ~/backups/mcp_memory_$(date +\%Y\%m\%d).sql.gz

# Keep last 30 days
0 3 * * * find ~/backups -name "mcp_memory_*.sql.gz" -mtime +30 -delete
```

---

## 6. Monitoring & Maintenance

### Health Monitoring

Add to your status-dashboard (status.iyeska.net):

```javascript
// Add new endpoint check
{
  id: 'mcp-memory',
  name: 'Memory MCP Server',
  type: 'http',
  url: 'http://192.168.11.20:3333/mcp/v1/health',
  group_name: 'iyeska'
}
```

### Log Management

```bash
# View server logs
sudo journalctl -u mcp-memory -f

# Or if using Docker
docker logs -f mcp-memory
```

### Performance Tuning

```sql
-- Monitor query performance
SELECT * FROM pg_stat_statements
WHERE query LIKE '%memories%'
ORDER BY mean_exec_time DESC;

-- Analyze and optimize
ANALYZE memories;

-- Update vector index if data grows
REINDEX INDEX idx_memories_embedding;
```

---

## 7. Alternative: Simpler File-Based Sync

If PostgreSQL is too complex, use shared JSONL file:

### Shared JSONL File over NetBird

```bash
# On Ubuntu server
sudo apt install nfs-kernel-server
sudo mkdir -p /srv/nfs/mcp-memory
sudo chown nobody:nogroup /srv/nfs/mcp-memory

# /etc/exports
/srv/nfs/mcp-memory 192.168.11.0/24(rw,sync,no_subtree_check)

sudo exportfs -a
sudo systemctl restart nfs-kernel-server

# On client Macs
sudo mount -t nfs 192.168.11.20:/srv/nfs/mcp-memory ~/mcp-shared
```

Client config:

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {
        "MEMORY_FILE_PATH": "/Users/username/mcp-shared/memory.jsonl"
      }
    }
  }
}
```

**Pros**: Simple, no server needed
**Cons**: File locking issues, no semantic search

---

## 8. Migration Path

### Export Existing Local Memory

```bash
# Backup current local memory
cat ~/.local/share/claude/memory.jsonl > local_backup.jsonl

# Convert to PostgreSQL format (create migration script)
node migrate-to-postgres.js local_backup.jsonl
```

---

## 9. Cost & Resource Analysis

**Hardware Costs**: $0 (using existing infrastructure)

**Resource Usage**:
- PostgreSQL: +50-100MB RAM (in existing container)
- Memory MCP Server: ~100MB RAM, <5% CPU
- Storage: ~10-100MB (depends on usage)

**Operational Costs**: $0 (all self-hosted)

---

## 10. Summary

### Why PostgreSQL + pgvector?

1. ✅ Leverages existing PostgreSQL infrastructure
2. ✅ Provides semantic search via pgvector
3. ✅ Battle-tested reliability
4. ✅ Fits data sovereignty principles
5. ✅ No additional costs
6. ✅ Scales to team usage if needed

### Estimated Effort

| Phase | Time | Complexity |
|-------|------|------------|
| Database setup | 30 min | Low |
| Server installation | 1-2 hours | Medium |
| Network configuration | 1 hour | Low |
| Client setup (per machine) | 30 min | Low |
| Testing | 30 min | Low |
| **Total** | **4-6 hours** | **Medium** |

### Next Steps

1. **Decide**: Confirm PostgreSQL approach
2. **Schedule**: Block 4-6 hours for implementation
3. **Backup**: Export existing local memory files
4. **Execute**: Follow Phase 1-5 implementation steps
5. **Test**: Verify multi-machine sync works
6. **Monitor**: Add to status dashboard

---

**Generated by**: Tier 3 Agent (2025-11-27)
**For**: Iyeska LLC Infrastructure
**Contact**: See SESSION_STATE.md for current project status
