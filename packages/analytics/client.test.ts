import { describe, it, expect, vi } from 'vitest';
import { createTelemetry } from './client';
const storage = () => { const values = new Map<string,string>(); return { getItem: async (key: string) => values.get(key) ?? null, setItem: async (key: string, value: string) => { values.set(key,value); } }; };
describe('studio outbox', () => {
  it('retries offline events with the same IDs and removes acknowledged events', async () => {
    const store = storage();
    const sent: string[][] = [];
    const send = vi.fn(async (_url, options) => { const batch = JSON.parse(String(options?.body)); sent.push(batch.map((e: {id:string})=>e.id)); if(sent.length===1)throw Error('offline'); return {ok:true,json:async()=>({accepted:sent.at(-1)})} as Response; });
    const client=createTelemetry('merge-drift',store,'https://example.test','test',send);
    await client.record('run_start'); await client.flush(); await client.flush(); await client.flush();
    expect(sent).toHaveLength(2); expect(sent[0]).toEqual(sent[1]);
  });
  it('restores a pending outbox after restart and honors opt out', async () => {
    const store=storage(); const send=vi.fn(async()=>({ok:false}) as Response);
    const first=createTelemetry('merge-drift',store,'https://example.test','test',send);
    await first.record('run_start');
    const second=createTelemetry('merge-drift',store,'https://example.test','test',send);
    await second.flush(); expect(send).toHaveBeenCalledOnce();
    await second.setEnabled(false); await second.record('run_end'); await second.flush();
    expect(send).toHaveBeenCalledOnce();
    const third=createTelemetry('merge-drift',store,'https://example.test','test',send); await third.ready; expect(third.isEnabled()).toBe(false);
  });
  it('requires opt in for new production installs', async () => {
    const send=vi.fn(); const client=createTelemetry('grid-foundry',storage(),'https://example.test','production',send);
    await client.record('session_start'); await client.flush(); expect(send).not.toHaveBeenCalled();
  });
});
