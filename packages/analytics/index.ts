export type EventName = 'game_start' | 'game_end' | 'session_duration' | 'round_completed' | 'reward_offer_shown' | 'reward_earned' | 'ad_request' | 'ad_loaded' | 'ad_shown' | 'ad_failed';
/** Optional local diagnostic counters only. No network endpoint, identifiers or revenue estimates. */
export function createCounters() {
  let enabled = false;
  const counts: Partial<Record<EventName, number>> = {};
  return {
    setEnabled(value: boolean) { enabled = value; if (!value) for (const key of Object.keys(counts) as EventName[]) delete counts[key]; },
    record(event: EventName) { if (enabled) counts[event] = (counts[event] ?? 0) + 1; },
    snapshot() { return { ...counts }; }
  };
}
