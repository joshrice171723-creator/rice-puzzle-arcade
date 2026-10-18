export type Fields = Record<string, string | number | boolean>;
export type StudioEvent = { id: string; player: string; session: string; game: string; environment: string; at: number; name: string; fields: Fields };
type Store = { getItem(key: string): Promise<string | null>; setItem(key: string, value: string): Promise<unknown> };
const uid = () => `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}-${Math.random().toString(36).slice(2)}`;
/** Bounded, persistent outbox. Acknowledgements remove only the submitted snapshot. */
export function createTelemetry(game: string, store: Store, endpoint: string, environment = 'test', send: typeof fetch = fetch) {
  const key = `studio:${game}:v1`;
  let player = uid(), session = uid(), queue: StudioEvent[] = [], enabled = environment !== 'production', sending = false;
  let writes = Promise.resolve();
  const persist = () => { const snapshot = JSON.stringify({ player, enabled, queue }); writes = writes.then(() => store.setItem(key, snapshot)).then(() => undefined).catch(() => {}); return writes; };
  const ready = store.getItem(key).then(raw => {
    if (!raw) return;
    const saved = JSON.parse(raw);
    if (typeof saved.player === 'string') player = saved.player;
    enabled = saved.enabled !== false;
    if (Array.isArray(saved.queue)) queue = saved.queue.filter((e: StudioEvent) => e.game === game && Date.now() - e.at < 7 * 86400000).slice(-500);
    if (!enabled) queue = [];
  }).catch(() => {});
  const flush = async () => {
    await ready;
    if (!enabled || !endpoint || sending || !queue.length) return;
    sending = true;
    const batch = queue.slice(0, 50), controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10000);
    try {
      const response = await send(endpoint, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(batch), signal: controller.signal });
      if (!response.ok) return;
      const ack = await response.json() as { accepted: string[] };
      const ids = new Set(ack.accepted);
      queue = queue.filter(e => !ids.has(e.id));
      await persist();
    } catch { /* Offline delivery retries on the next flush. Gameplay never waits. */ }
    finally { clearTimeout(timeout); sending = false; }
  };
  return {
    ready,
    isEnabled: () => enabled,
    async setEnabled(value: boolean) { await ready; enabled = value; if (!value) { queue = []; player = uid(); session = uid(); } await persist(); },
    async record(name: string, fields: Fields = {}) {
      await ready;
      if (!enabled || !endpoint) return;
      queue.push({ id: uid(), player, session, game, environment, at: Date.now(), name, fields });
      queue = queue.slice(-500);
      await persist();
    },
    flush,
  };
}
