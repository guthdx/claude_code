-- Status Dashboard Database Schema
-- Cloudflare D1 (SQLite)

-- Services table
CREATE TABLE IF NOT EXISTS services (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL, -- 'http', 'ssh', 'ping'
  url TEXT NOT NULL,
  group_name TEXT NOT NULL, -- 'nativebio', 'tdr', 'mbiri', 'iyeska'
  check_interval INTEGER DEFAULT 600, -- seconds (10 minutes)
  created_at INTEGER DEFAULT (strftime('%s', 'now'))
);

-- Status checks table
CREATE TABLE IF NOT EXISTS status_checks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  service_id TEXT NOT NULL,
  status TEXT NOT NULL, -- 'online', 'offline', 'degraded'
  response_time INTEGER, -- milliseconds
  error_message TEXT,
  checked_at INTEGER DEFAULT (strftime('%s', 'now')),
  FOREIGN KEY (service_id) REFERENCES services(id)
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_status_checks_service_time
ON status_checks(service_id, checked_at DESC);

CREATE INDEX IF NOT EXISTS idx_status_checks_time
ON status_checks(checked_at DESC);

-- Insert initial services
INSERT INTO services (id, name, type, url, group_name) VALUES
-- NativeBio
('nativebio-proxmox', 'Proxmox 8 VE', 'http', 'http://68.168.225.3:8006', 'nativebio'),
('nativebio-pfsense', 'pfSense', 'http', 'http://68.168.225.3:81', 'nativebio'),

-- TDR
('tdr-proxmox', 'Proxmox 9 VE', 'http', 'http://68.168.225.3:8007', 'tdr'),

-- Missouri Breaks
('mbiri-pfsense', 'pfSense External', 'http', 'http://68.168.224.236', 'mbiri'),

-- Iyeska
('iyeska-n8n', 'n8n Automation', 'http', 'https://n8n.iyeska.net', 'iyeska'),
('iyeska-wowasi', 'Wowasi API', 'http', 'https://wowasi.iyeska.net', 'iyeska'),
('iyeska-pfsense', 'pfSense External', 'http', 'http://68.168.225.52', 'iyeska');
