/**
 * Status Checker Worker
 * Runs every 10 minutes to check all services and store results in D1
 */

export default {
  async scheduled(event, env, ctx) {
    console.log('Starting status checks...');
    await checkAllServices(env);
  },

  async fetch(request, env) {
    // Manual trigger endpoint for testing
    if (request.method === 'POST') {
      await checkAllServices(env);
      return new Response('Status check triggered', { status: 200 });
    }

    return new Response('Status Checker Worker - Use POST to trigger manually', {
      status: 200
    });
  }
};

async function checkAllServices(env) {
  try {
    // Get all services from database
    const { results: services } = await env.DB.prepare(
      'SELECT id, name, type, url FROM services'
    ).all();

    console.log(`Checking ${services.length} services...`);

    // Check each service
    const checks = await Promise.allSettled(
      services.map(service => checkService(service, env))
    );

    console.log(`Completed ${checks.length} checks`);

    // Log any failures
    const failures = checks.filter(c => c.status === 'rejected');
    if (failures.length > 0) {
      console.error(`${failures.length} checks failed:`, failures);
    }

  } catch (error) {
    console.error('Error in checkAllServices:', error);
  }
}

async function checkService(service, env) {
  const startTime = Date.now();
  let status = 'offline';
  let responseTime = null;
  let errorMessage = null;

  try {
    if (service.type === 'http') {
      // HTTP/HTTPS check
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 10000); // 10s timeout

      try {
        const response = await fetch(service.url, {
          method: 'HEAD',
          signal: controller.signal,
          // Don't follow redirects for faster checks
          redirect: 'manual'
        });

        clearTimeout(timeout);
        responseTime = Date.now() - startTime;

        // Consider 2xx, 3xx, 401, 403 as "online" (server responding)
        // 401/403 means server is up but requires auth (which is expected)
        if (
          (response.status >= 200 && response.status < 400) ||
          response.status === 401 ||
          response.status === 403
        ) {
          status = 'online';
        } else {
          status = 'degraded';
          errorMessage = `HTTP ${response.status}`;
        }
      } catch (fetchError) {
        clearTimeout(timeout);
        if (fetchError.name === 'AbortError') {
          errorMessage = 'Timeout (>10s)';
        } else {
          errorMessage = fetchError.message || 'Connection failed';
        }
      }

    } else if (service.type === 'ssh') {
      // For SSH, we can't actually connect, but we can check if port 22 responds
      // This is a TCP check via HTTP CONNECT (limited in Workers)
      // For now, mark as checking
      status = 'checking';
      errorMessage = 'SSH checks not yet implemented';

    } else if (service.type === 'ping') {
      // ICMP ping not available in Workers
      // We'll use HTTP as fallback
      status = 'checking';
      errorMessage = 'Ping checks not yet implemented';
    }

  } catch (error) {
    console.error(`Error checking ${service.id}:`, error);
    errorMessage = error.message || 'Check failed';
  }

  // Store result in database
  try {
    await env.DB.prepare(`
      INSERT INTO status_checks (service_id, status, response_time, error_message, checked_at)
      VALUES (?, ?, ?, ?, strftime('%s', 'now'))
    `).bind(
      service.id,
      status,
      responseTime,
      errorMessage
    ).run();

    console.log(`${service.id}: ${status} (${responseTime}ms)`);

    // Check if service just went down (trigger alert)
    await checkForDowntime(service, status, env);

  } catch (dbError) {
    console.error(`Error storing check result for ${service.id}:`, dbError);
  }
}

async function checkForDowntime(service, currentStatus, env) {
  if (currentStatus !== 'offline') return;

  // Get last 3 checks for this service
  const { results: recentChecks } = await env.DB.prepare(`
    SELECT status FROM status_checks
    WHERE service_id = ?
    ORDER BY checked_at DESC
    LIMIT 3
  `).bind(service.id).all();

  // If this is the first offline after being online, trigger alert
  if (recentChecks.length >= 2) {
    const previousStatus = recentChecks[1]?.status;
    if (previousStatus === 'online') {
      console.log(`⚠️  ALERT: ${service.id} just went DOWN`);

      // Trigger webhook to n8n (when configured)
      if (env.N8N_WEBHOOK_URL) {
        try {
          await fetch(env.N8N_WEBHOOK_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              service: service.name,
              serviceId: service.id,
              status: currentStatus,
              timestamp: new Date().toISOString(),
              message: `${service.name} is now offline`
            })
          });
        } catch (webhookError) {
          console.error('Failed to send webhook:', webhookError);
        }
      }
    }
  }
}
