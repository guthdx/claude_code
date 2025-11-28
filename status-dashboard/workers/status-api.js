/**
 * Status API Worker
 * Serves current status data to the dashboard frontend
 */

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Route handling
    if (url.pathname === '/api/status' || url.pathname === '/api/status/') {
      return handleStatus(env, corsHeaders);
    }

    if (url.pathname.startsWith('/api/history/')) {
      const serviceId = url.pathname.split('/').pop();
      return handleHistory(serviceId, env, corsHeaders);
    }

    return new Response('Status API - Available endpoints: /api/status, /api/history/{service_id}', {
      status: 404,
      headers: corsHeaders
    });
  }
};

async function handleStatus(env, corsHeaders) {
  try {
    // Get all services
    const { results: services } = await env.DB.prepare(`
      SELECT id, name, type, url, group_name FROM services
    `).all();

    // Get latest status for each service
    const statusData = {};

    for (const service of services) {
      // Get last check
      const { results: checks } = await env.DB.prepare(`
        SELECT status, response_time, error_message, checked_at
        FROM status_checks
        WHERE service_id = ?
        ORDER BY checked_at DESC
        LIMIT 1
      `).bind(service.id).all();

      const lastCheck = checks[0];

      // Calculate uptime percentage (last 24 hours)
      const { results: uptimeData } = await env.DB.prepare(`
        SELECT
          COUNT(*) as total_checks,
          SUM(CASE WHEN status = 'online' THEN 1 ELSE 0 END) as online_checks
        FROM status_checks
        WHERE service_id = ?
          AND checked_at > strftime('%s', 'now', '-24 hours')
      `).bind(service.id).all();

      const uptime = uptimeData[0]
        ? (uptimeData[0].online_checks / uptimeData[0].total_checks) * 100
        : null;

      statusData[service.id] = {
        status: lastCheck?.status || 'unknown',
        uptime: uptime !== null ? parseFloat(uptime.toFixed(1)) : null,
        responseTime: lastCheck?.response_time || null,
        lastCheck: lastCheck?.checked_at || null,
        errorMessage: lastCheck?.error_message || null
      };
    }

    const response = {
      timestamp: new Date().toISOString(),
      services: statusData
    };

    return new Response(JSON.stringify(response, null, 2), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=60' // Cache for 1 minute
      }
    });

  } catch (error) {
    console.error('Error in handleStatus:', error);
    return new Response(JSON.stringify({
      error: 'Failed to fetch status data',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
}

async function handleHistory(serviceId, env, corsHeaders) {
  try {
    // Get last 24 hours of checks for this service
    const { results: checks } = await env.DB.prepare(`
      SELECT
        status,
        response_time,
        checked_at
      FROM status_checks
      WHERE service_id = ?
        AND checked_at > strftime('%s', 'now', '-24 hours')
      ORDER BY checked_at ASC
    `).bind(serviceId).all();

    const response = {
      serviceId,
      history: checks.map(c => ({
        status: c.status,
        responseTime: c.response_time,
        timestamp: c.checked_at
      }))
    };

    return new Response(JSON.stringify(response, null, 2), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=300' // Cache for 5 minutes
      }
    });

  } catch (error) {
    console.error('Error in handleHistory:', error);
    return new Response(JSON.stringify({
      error: 'Failed to fetch history data',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
}
