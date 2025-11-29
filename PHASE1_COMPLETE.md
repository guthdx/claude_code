# Phase 1 Complete: PostgreSQL Memory MCP Database Setup

**Date**: 2025-11-29
**Server**: IyeskaLLC (192.168.11.20)
**Status**: ✅ COMPLETE

## Summary

Successfully set up the PostgreSQL database for Memory MCP shared backend on the NetBird PostgreSQL container.

## What Was Created

### 1. Database
- **Name**: `mcp_memory`
- **Owner**: `root`
- **Encoding**: UTF8
- **Location**: NetBird PostgreSQL container `netbird-zdb-1`

### 2. Extensions
- **pgvector**: v0.6.2 ✅ Installed and enabled
  - Built from source and manually installed
  - Supports vector similarity search with 384-dimensional embeddings

### 3. Database User
- **Username**: `mcp_user`
- **Password**: `DIvT7IVF/sTYaxYxlxBAbPPFZod3LwcJqJHRDlVJAAg=`
- **Permissions**:
  - `GRANT ALL PRIVILEGES ON DATABASE mcp_memory`
  - `GRANT ALL ON SCHEMA public`
  - `GRANT ALL ON memories TABLE`
  - `ALTER DEFAULT PRIVILEGES` for future tables and sequences

### 4. Schema

#### Table: `memories`
```sql
CREATE TABLE memories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type VARCHAR(50) NOT NULL,
  content JSONB NOT NULL,
  source VARCHAR(100),
  embedding vector(384),
  tags TEXT[],
  confidence FLOAT CHECK (confidence >= 0 AND confidence <= 1),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### Indexes
1. **Primary Key**: `memories_pkey` - btree on `id`
2. **Type Index**: `idx_memories_type` - btree on `type`
3. **Tags Index**: `idx_memories_tags` - GIN on `tags`
4. **Content Index**: `idx_memories_content` - GIN on `content` (JSONB search)
5. **Vector Index**: `idx_memories_embedding` - ivfflat on `embedding` with cosine similarity

## Connection Information

### Connection String
```
postgresql://mcp_user:DIvT7IVF/sTYaxYxlxBAbPPFZod3LwcJqJHRDlVJAAg=@localhost:5432/mcp_memory
```

### From Docker Host (Ubuntu Server)
```bash
docker exec netbird-zdb-1 psql -U mcp_user -d mcp_memory
```

### From Remote Machines (over NetBird VPN)
```bash
psql -h 192.168.11.20 -p 5432 -U mcp_user -d mcp_memory
```

**Note**: Port 5432 needs to be exposed from the container for remote access.

## Verification Tests

### ✅ Database Created
```sql
SELECT datname FROM pg_database WHERE datname = 'mcp_memory';
-- Returns: mcp_memory
```

### ✅ pgvector Extension Enabled
```sql
SELECT * FROM pg_extension WHERE extname = 'vector';
-- Returns: vector v0.6.2
```

### ✅ User Can Connect
```bash
docker exec netbird-zdb-1 psql -U mcp_user -d mcp_memory -c "SELECT version();"
-- Returns: PostgreSQL 16.10
```

### ✅ User Has Table Access
```sql
SELECT COUNT(*) FROM memories;
-- Returns: 0 (table is empty)
```

### ✅ All Indexes Created
```sql
\di
-- Shows 5 indexes on memories table
```

## PostgreSQL Container Details

- **Container Name**: `netbird-zdb-1`
- **Image**: `postgres:16-alpine`
- **OS**: Alpine Linux v3.22
- **PostgreSQL Version**: 16.10
- **Root User**: `root` (password in `~/zdb.env`)
- **Status**: Running and healthy (4 days uptime)

## pgvector Installation Notes

The standard Alpine package `postgresql-pgvector` was for PostgreSQL 17, but the container runs PostgreSQL 16.

**Solution**: Built pgvector v0.6.2 from source and manually installed:
1. Installed build dependencies: `git`, `build-base`, `postgresql16-dev`
2. Cloned pgvector v0.6.2 from GitHub
3. Compiled with `make` (gcc)
4. Manually copied files:
   - `vector.so` → `/usr/local/lib/postgresql/`
   - `vector--*.sql` → `/usr/local/share/postgresql/extension/`
   - `vector.control` → `/usr/local/share/postgresql/extension/`

## Security Considerations

### ✅ Current Security
- Database only accessible within NetBird PostgreSQL container
- Strong random password (32 bytes, base64 encoded)
- User has minimal required permissions (no SUPERUSER)

### ⚠️ For Production
1. **Port Exposure**: Container port 5432 is not exposed to host - need to expose for remote access
2. **SSL/TLS**: Consider enabling SSL for encrypted connections
3. **Firewall**: Restrict access to NetBird VPN subnet (192.168.11.0/24)
4. **Backup**: Set up automated backups (see Phase 2)

## Next Steps - Phase 2

Ready to proceed with Phase 2: Memory MCP Server Installation

**Prerequisites Met**:
- ✅ Database created: `mcp_memory`
- ✅ pgvector extension enabled
- ✅ User credentials ready: `mcp_user` / password
- ✅ Schema and indexes created
- ✅ Connection verified

**Phase 2 Tasks**:
1. Expose PostgreSQL port from container (or use host network)
2. Clone and install Memory MCP Server (sdimitrov/mcp-memory or custom)
3. Configure `.env` with connection string
4. Initialize server with Prisma migrations
5. Start server and verify API endpoints
6. Set up systemd service for auto-start

## Troubleshooting

### Connect to Database
```bash
# As root user
docker exec netbird-zdb-1 psql -U root -d mcp_memory

# As mcp_user
docker exec netbird-zdb-1 psql -U mcp_user -d mcp_memory
```

### Check Extension Status
```sql
SELECT * FROM pg_available_extensions WHERE name = 'vector';
SELECT * FROM pg_extension WHERE extname = 'vector';
```

### View Table Schema
```sql
\d memories
\di  -- List indexes
```

### Test Vector Operations
```sql
-- Insert test memory with embedding
INSERT INTO memories (type, content, tags, confidence, embedding)
VALUES (
  'test',
  '{"message": "Hello from Phase 1"}'::jsonb,
  ARRAY['setup', 'test'],
  0.95,
  '[0.1,0.2,0.3]'::vector  -- Truncated for demo
);

-- Query memories
SELECT id, type, content->>'message' as message FROM memories;
```

## Credentials Storage

**⚠️ IMPORTANT**: Store these credentials securely!

### Connection Details
- **Host**: 192.168.11.20 (NetBird server)
- **Port**: 5432 (internal to container - not yet exposed)
- **Database**: mcp_memory
- **User**: mcp_user
- **Password**: `DIvT7IVF/sTYaxYxlxBAbPPFZod3LwcJqJHRDlVJAAg=`

### Add to Environment Variables
```bash
# On each client machine, add to ~/.zshrc or ~/.bashrc
export MCP_MEMORY_DB="postgresql://mcp_user:DIvT7IVF/sTYaxYxlxBAbPPFZod3LwcJqJHRDlVJAAg=@192.168.11.20:5432/mcp_memory"
```

---

**Phase 1 Status**: ✅ COMPLETE - Ready for Phase 2
**Completion Time**: ~45 minutes (including pgvector compilation)
**Issues Encountered**: pgvector not available for PostgreSQL 16 in Alpine repos - resolved by building from source
