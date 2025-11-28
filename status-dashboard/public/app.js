// Status Dashboard JavaScript
// Fetches status data from Cloudflare Worker API and updates UI

const API_ENDPOINT = 'https://status.iyeska.net/api/status';
const REFRESH_INTERVAL = 60000; // 1 minute

// Initialize dashboard
document.addEventListener('DOMContentLoaded', () => {
  loadStatus();
  setInterval(loadStatus, REFRESH_INTERVAL);
});

async function loadStatus() {
  try {
    const response = await fetch(API_ENDPOINT);
    const data = await response.json();

    updateDashboard(data);
    updateLastCheck();
  } catch (error) {
    console.error('Failed to load status:', error);
    showError();
  }
}

function getMockStatus() {
  // Mock data for development
  // Simulates what the Worker API will return
  return {
    timestamp: new Date().toISOString(),
    services: {
      // NativeBio
      'nativebio-proxmox': { status: 'offline', uptime: 0, responseTime: null },
      'nativebio-tdr-vm': { status: 'offline', uptime: 0, responseTime: null },
      'nativebio-ubuntu-cli': { status: 'offline', uptime: 0, responseTime: null },
      'nativebio-ubuntu-desktop': { status: 'offline', uptime: 0, responseTime: null },
      'nativebio-redcap': { status: 'offline', uptime: 0, responseTime: null },
      'nativebio-pfsense': { status: 'offline', uptime: 0, responseTime: null },

      // TDR
      'tdr-proxmox': { status: 'offline', uptime: 0, responseTime: null },
      'tdr-data-vm': { status: 'offline', uptime: 0, responseTime: null },
      'tdr-backup-vm': { status: 'offline', uptime: 0, responseTime: null },
      'tdr-portal-vm': { status: 'offline', uptime: 0, responseTime: null },
      'tdr-website-vm': { status: 'offline', uptime: 0, responseTime: null },
      'tdr-cli-vm': { status: 'offline', uptime: 0, responseTime: null },
      'tdr-desktop-vm': { status: 'offline', uptime: 0, responseTime: null },

      // Missouri Breaks
      'mbiri-external': { status: 'online', uptime: 99.8, responseTime: 145 },
      'mbiri-pfsense': { status: 'online', uptime: 99.9, responseTime: 89 },

      // Iyeska (currently down due to power outage)
      'iyeska-main': { status: 'offline', uptime: 98.5, responseTime: null },
      'iyeska-n8n': { status: 'offline', uptime: 97.2, responseTime: null },
      'iyeska-wowasi': { status: 'offline', uptime: 95.1, responseTime: null },
      'iyeska-laptop': { status: 'offline', uptime: 89.3, responseTime: null },
      'iyeska-pi': { status: 'offline', uptime: 96.7, responseTime: null },
      'iyeska-pfsense': { status: 'offline', uptime: 99.1, responseTime: null },
    }
  };
}

function updateDashboard(data) {
  // Update each service status
  Object.entries(data.services).forEach(([serviceId, serviceData]) => {
    updateServiceStatus(serviceId, serviceData);
  });

  // Update section status indicators
  updateSectionStatus('nativebio', data.services);
  updateSectionStatus('tdr', data.services);
  updateSectionStatus('mbiri', data.services);
  updateSectionStatus('iyeska', data.services);

  // Update overall status
  updateOverallStatus(data.services);
}

function updateServiceStatus(serviceId, data) {
  const { status, uptime, responseTime } = data;

  // Update status dot
  const dot = document.querySelector(`[data-service="${serviceId}"]`);
  if (dot) {
    dot.className = 'status-dot';
    if (status === 'online') {
      dot.classList.add('status-online');
    } else if (status === 'degraded') {
      dot.classList.add('status-degraded');
    } else {
      dot.classList.add('status-offline');
    }
  }

  // Update uptime
  const uptimeElement = document.querySelector(`[data-uptime="${serviceId}"]`);
  if (uptimeElement) {
    if (uptime !== null && uptime !== undefined) {
      uptimeElement.textContent = `${uptime.toFixed(1)}%`;
    } else {
      uptimeElement.textContent = '--';
    }
  }

  // Update response time
  const responseElement = document.querySelector(`[data-response="${serviceId}"]`);
  if (responseElement) {
    if (responseTime !== null && responseTime !== undefined) {
      responseElement.textContent = `${responseTime}ms`;
    } else {
      responseElement.textContent = '--';
    }
  }
}

function updateSectionStatus(sectionId, services) {
  const sectionDot = document.getElementById(`status-${sectionId}`);
  if (!sectionDot) return;

  // Get all services in this section
  const sectionServices = Object.entries(services)
    .filter(([id]) => id.startsWith(sectionId))
    .map(([, data]) => data.status);

  if (sectionServices.length === 0) return;

  // Determine section status
  const allOnline = sectionServices.every(s => s === 'online');
  const allOffline = sectionServices.every(s => s === 'offline');
  const hasDegraded = sectionServices.some(s => s === 'degraded');

  sectionDot.className = 'status-dot';
  if (allOnline) {
    sectionDot.classList.add('status-online');
  } else if (allOffline) {
    sectionDot.classList.add('status-offline');
  } else if (hasDegraded) {
    sectionDot.classList.add('status-degraded');
  } else {
    sectionDot.classList.add('status-degraded');
  }
}

function updateOverallStatus(services) {
  const statuses = Object.values(services).map(s => s.status);
  const onlineCount = statuses.filter(s => s === 'online').length;
  const totalCount = statuses.length;

  const overallElement = document.getElementById('overall-status');
  if (!overallElement) return;

  const percentage = (onlineCount / totalCount) * 100;
  let statusText;
  let statusClass;

  if (percentage === 100) {
    statusText = 'All Systems Operational';
    statusClass = 'status-online';
  } else if (percentage >= 75) {
    statusText = 'Partial Outage';
    statusClass = 'status-degraded';
  } else if (percentage >= 25) {
    statusText = 'Major Outage';
    statusClass = 'status-degraded';
  } else {
    statusText = 'Critical Outage';
    statusClass = 'status-offline';
  }

  overallElement.innerHTML = `
    <span class="status-dot ${statusClass}"></span>
    ${statusText} (${onlineCount}/${totalCount} services online)
  `;
}

function updateLastCheck() {
  const lastCheckElement = document.getElementById('last-check');
  if (lastCheckElement) {
    const now = new Date();
    lastCheckElement.textContent = `Last checked: ${now.toLocaleTimeString()}`;
  }
}

function showError() {
  const overallElement = document.getElementById('overall-status');
  if (overallElement) {
    overallElement.innerHTML = `
      <span class="status-dot status-offline"></span>
      Error loading status data
    `;
  }
}
