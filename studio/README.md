# Game Studio

Private dashboard: https://aimetaclinic.com/games/
Collector: https://aimetaclinic.com/games/api/events

Run locally: `python studio/server.py`, then open http://127.0.0.1:8090/games/.
Tests: `python -m unittest discover -s studio -p test_server.py` and `pnpm test`.

## Measurements
All three games share the client in packages/analytics/client.ts. Session start, foreground play heartbeats, run start/resume/progress/exit/end, boost offers/requests/earned rewards and actual SDK ad lifecycle events are recorded. Persisted outbox: 500 events, 50-event batches, seven-day client expiry, ten-second timeout. IDs deduplicate server retries. Gameplay never waits for telemetry. Closed/crashed apps can leave unfinished runs; these are not claimed as confirmed churn. Resumed rewarded runs use their latest outcome. Progression-rule losses are distinguished from natural board/timer losses. Installation IDs are per game, not cross-app people. Ad outcomes have no revenue or estimated dollar values. Daily bars measure UTC activity, not cohort retention.

Reports filter test versus production and 1/7/30/90 days, compare all games, show per-level attempts/outcomes and recent events, and export aggregate JSON. New production installations default to analytics off. The Privacy & support toggle controls collection. Internal builds use test data by default. Public ingestion is untrusted client telemetry, not verified revenue; no secret embedded in apps can authenticate players. Request/schema/size/rate limits mitigate abuse, but public clients can fabricate events. Do not use these reports for billing.

## Hosting
Separate Python standard-library service; SQLite outside code at /var/lib/game-studio/events.sqlite3. Nginx protects the dashboard and reports with HTTP Basic authentication over TLS. Only event ingestion is public. Service binds loopback; network logs disabled for ingestion. Existing clinic containers and data remain independent. The collector retains events for 90 days (pruned on ingestion); schedule additional pruning if no traffic is expected. No separate crash reporting or cohort retention calculation yet.

Deploy a versioned source directory under /opt/game-studio/releases, point current at it, install game-studio.service and games.nginx.conf, and configure studio_ingest rate zone. Generate credentials outside Git, preserve the previous current symlink and nginx config, validate nginx before reload. Rollback restores the symlink and nginx backup. Back up /var/lib/game-studio/events.sqlite3 using SQLite backup before replacing the schema. Keep credentials in the owner's Secure Files directory. This initial collector has no schema migrations.

The nginx snippet also serves public /app-ads.txt from /var/www/game-publisher/app-ads.txt. Install website/app-ads.txt there when deploying; retain this exact location on future updates. Studio authentication is unchanged.
