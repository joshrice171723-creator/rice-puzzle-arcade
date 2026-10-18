import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { AdsService, type AdEvent, type AdFormat, type AdHandle, type AdsAdapter } from './AdsService';
import { createAdsService } from './index.web';

class MockAd implements AdHandle {
  listeners = new Map<AdEvent, Set<() => void>>();
  load = vi.fn(() => this.emit('loaded'));
  show = vi.fn(async () => { this.emit('opened'); });
  destroy = vi.fn(() => this.listeners.clear());
  on(event: AdEvent, callback: () => void) {
    const listeners = this.listeners.get(event) ?? new Set();
    listeners.add(callback);
    this.listeners.set(event, listeners);
    return () => { listeners.delete(callback); };
  }
  emit(event: AdEvent) { for (const callback of [...this.listeners.get(event) ?? []]) callback(); }
}

function setup({ allowed = true, load = true } = {}) {
  const handles: Record<AdFormat, MockAd[]> = { rewarded: [], interstitial: [] };
  const adapter: AdsAdapter = {
    supported: true,
    gatherConsent: vi.fn(async () => ({ canRequestAds: allowed, privacyOptionsRequired: true })),
    privacyOptions: vi.fn(async () => ({ canRequestAds: false, privacyOptionsRequired: true })),
    initialize: vi.fn(async () => undefined),
    isForeground: vi.fn(() => true),
    create: vi.fn((format: AdFormat) => {
      const handle = new MockAd();
      if (!load) handle.load = vi.fn();
      handles[format].push(handle);
      return handle;
    }),
  };
  const service = new AdsService(adapter);
  return { service, adapter, handles, current: (format: AdFormat) => handles[format].at(-1)! };
}

describe('consent and loading', () => {
  beforeEach(() => { vi.useFakeTimers(); vi.setSystemTime(0); });
  afterEach(() => { vi.clearAllTimers(); vi.useRealTimers(); });

  it('reports actual SDK impressions and only one earned event', async () => {
    const { service, current } = setup();
    const events: string[] = [];
    service.subscribeEvents((name, fields) => events.push(`${fields.format}:${name}`));
    await service.initializeAfterConsent();
    expect(events).toContain('rewarded:ad_request');
    expect(events).toContain('rewarded:ad_loaded');
    expect(events).not.toContain('rewarded:ad_shown');
    const handle = current('rewarded');
    const shown = service.showRewardedIfReady(() => {});
    handle.emit('earned'); handle.emit('earned'); handle.emit('closed');
    await shown;
    expect(events.filter(e => e === 'rewarded:ad_earned')).toHaveLength(1);
    expect(events.filter(e => e === 'rewarded:ad_shown')).toHaveLength(1);
    service.dispose();
  });

  it('does not load or initialize before consent; coalesces launch calls', async () => {
    const { service, adapter } = setup();
    service.preload();
    expect(adapter.create).not.toHaveBeenCalled();
    const first = service.initializeAfterConsent();
    expect(service.initializeAfterConsent()).toBe(first);
    expect((await first).code).toBe('ready');
    expect(adapter.initialize).toHaveBeenCalledOnce();
    expect(service.isReady('rewarded')).toBe(true);
    await service.initializeAfterConsent();
    expect(adapter.gatherConsent).toHaveBeenCalledOnce();
    service.dispose();
  });

  it('recovers initialization after a temporary consent network failure', async () => {
    const { service, adapter } = setup();
    adapter.gatherConsent = vi.fn()
      .mockRejectedValueOnce(new Error('offline'))
      .mockResolvedValue({ canRequestAds: true, privacyOptionsRequired: false });
    expect((await service.initializeAfterConsent()).code).toBe('failed');
    expect(adapter.initialize).not.toHaveBeenCalled();
    expect((await service.initializeAfterConsent()).code).toBe('ready');
    expect(service.isReady('rewarded')).toBe(true);
    expect(adapter.initialize).toHaveBeenCalledOnce();
    service.dispose();
  });

  it('unknown or declined permission permits gameplay but no SDK requests', async () => {
    const { service, adapter } = setup({ allowed: false });
    expect((await service.initializeAfterConsent()).code).toBe('consent_required');
    expect((await service.showRewardedIfReady(vi.fn())).code).toBe('consent_required');
    expect(adapter.initialize).not.toHaveBeenCalled();
    expect(adapter.create).not.toHaveBeenCalled();
    service.dispose();
  });

  it('consent refresh failure and SDK initialization failure fail closed', async () => {
    for (const fail of ['gatherConsent', 'initialize'] as const) {
      const { service, adapter } = setup();
      adapter[fail] = vi.fn(async () => { throw new Error('offline'); });
      expect((await service.initializeAfterConsent()).code).toBe('failed');
      expect(service.getState().busy).toBe(false);
      expect(service.isReady('rewarded')).toBe(false);
      expect(adapter.create).not.toHaveBeenCalled();
      service.dispose();
    }
  });

  it('consent timeout releases game pause and ignores late approval', async () => {
    const { service, adapter } = setup();
    let resolve!: (value: { canRequestAds: boolean; privacyOptionsRequired: boolean }) => void;
    adapter.gatherConsent = () => new Promise(done => { resolve = done; });
    const operation = service.initializeAfterConsent();
    await vi.advanceTimersByTimeAsync(30_000);
    expect((await operation).code).toBe('timeout');
    resolve({ canRequestAds: true, privacyOptionsRequired: true });
    await Promise.resolve();
    expect(adapter.initialize).not.toHaveBeenCalled();
    expect(service.getState().busy).toBe(false);
    service.dispose();
  });

  it('load timeout cleans listeners and allows explicit preload retry', async () => {
    const { service, current, handles } = setup({ load: false });
    await service.initializeAfterConsent();
    const old = current('rewarded');
    service.preload();
    expect(handles.rewarded).toHaveLength(1);
    await vi.advanceTimersByTimeAsync(15_000);
    expect(old.destroy).toHaveBeenCalledOnce();
    expect(old.listeners.size).toBe(0);
    expect(service.isReady('rewarded')).toBe(false);
    service.preload();
    expect(handles.rewarded).toHaveLength(2);
    service.dispose();
  });

  it('load errors clear inventory without rewarding', async () => {
    const { service, current } = setup({ load: false });
    await service.initializeAfterConsent();
    current('rewarded').emit('error');
    expect(service.getState().lastResult).toBe('failed');
    expect(service.isReady('rewarded')).toBe(false);
    service.dispose();
  });

  it('privacy changes destroy cached inventory before revoking request permission', async () => {
    const { service, current } = setup();
    await service.initializeAfterConsent();
    const old = current('rewarded');
    expect((await service.showPrivacyOptions()).code).toBe('consent_required');
    expect(old.destroy).toHaveBeenCalledOnce();
    expect(service.getState().privacyOptionsRequired).toBe(true);
    expect(service.isReady('rewarded')).toBe(false);
    service.dispose();
  });

  it('stale inventory cannot be shown and is reloaded', async () => {
    const { service, current } = setup();
    await service.initializeAfterConsent();
    const old = current('rewarded');
    await vi.advanceTimersByTimeAsync(55 * 60_000);
    expect(service.isReady('rewarded')).toBe(false);
    expect((await service.showRewardedIfReady(vi.fn())).code).toBe('not_ready');
    expect(old.show).not.toHaveBeenCalled();
    expect(service.isReady('rewarded')).toBe(true);
    service.dispose();
  });

  it('browser has zero ads and never simulates reward', async () => {
    const service = createAdsService('grid-foundry');
    const reward = vi.fn();
    expect((await service.initializeAfterConsent()).code).toBe('unsupported');
    expect((await service.showRewardedIfReady(reward)).code).toBe('unsupported');
    expect(service.isReady('rewarded')).toBe(false);
    expect(reward).not.toHaveBeenCalled();
    service.dispose();
  });
});

describe('full-screen lifecycle', () => {
  beforeEach(() => { vi.useFakeTimers(); vi.setSystemTime(0); });
  afterEach(() => { vi.clearAllTimers(); vi.useRealTimers(); });

  it('rewards once only from earned SDK callback, including duplicates', async () => {
    const { service, current } = setup();
    await service.initializeAfterConsent();
    const reward = vi.fn();
    const ad = current('rewarded');
    const operation = service.showRewardedIfReady(reward);
    expect(reward).not.toHaveBeenCalled();
    ad.emit('earned'); ad.emit('earned'); ad.emit('closed'); ad.emit('earned');
    expect(await operation).toEqual({ code: 'rewarded', earned: true });
    expect(reward).toHaveBeenCalledOnce();
    expect(service.getState().busy).toBe(false);
    expect(ad.listeners.size).toBe(0);
    service.dispose();
  });

  it.each(['closed', 'error'] as const)('%s without earned callback grants nothing', async event => {
    const { service, current } = setup();
    await service.initializeAfterConsent();
    const reward = vi.fn();
    const ad = current('rewarded');
    const operation = service.showRewardedIfReady(reward);
    ad.emit(event);
    expect((await operation).earned).toBe(false);
    expect(reward).not.toHaveBeenCalled();
    service.dispose();
  });

  it('no fill and background show attempts cannot reward or open fullscreen', async () => {
    const { service, adapter, current } = setup({ load: false });
    await service.initializeAfterConsent();
    const reward = vi.fn();
    expect((await service.showRewardedIfReady(reward)).code).toBe('not_ready');
    current('rewarded').emit('loaded');
    adapter.isForeground = () => false;
    expect((await service.showRewardedIfReady(reward)).code).toBe('invalid_transition');
    expect(reward).not.toHaveBeenCalled();
    expect(current('rewarded').show).not.toHaveBeenCalled();
    service.dispose();
  });

  it('double tap and privacy dialog cannot open another fullscreen', async () => {
    const { service, current } = setup();
    await service.initializeAfterConsent();
    const ad = current('rewarded');
    const operation = service.showRewardedIfReady(vi.fn());
    expect((await service.showRewardedIfReady(vi.fn())).code).toBe('busy');
    expect((await service.showPrivacyOptions()).code).toBe('busy');
    expect(ad.show).toHaveBeenCalledOnce();
    ad.emit('closed'); await operation;
    service.dispose();
  });

  it('show rejection fails safely and preserves replay', async () => {
    const { service, current } = setup();
    await service.initializeAfterConsent();
    current('rewarded').show = vi.fn(async () => { throw new Error('show failure'); });
    const reward = vi.fn();
    expect((await service.showRewardedIfReady(reward)).code).toBe('failed');
    expect(service.getState().busy).toBe(false);
    expect(reward).not.toHaveBeenCalled();
    service.dispose();
  });

  it('missing close callback times out, rejects late rewards and disables further session ads', async () => {
    const { service, current } = setup();
    await service.initializeAfterConsent();
    const ad = current('rewarded');
    const reward = vi.fn();
    const operation = service.showRewardedIfReady(reward);
    await vi.advanceTimersByTimeAsync(180_000);
    expect((await operation).code).toBe('timeout');
    expect(service.getState().busy).toBe(false);
    ad.emit('earned');
    expect(reward).not.toHaveBeenCalled();
    expect(service.isReady('rewarded')).toBe(false);
    service.dispose();
  });

  it('disposing during a video resolves pending caller and prevents late rewards', async () => {
    const { service, current } = setup();
    await service.initializeAfterConsent();
    const ad = current('rewarded');
    const reward = vi.fn();
    const operation = service.showRewardedIfReady(reward);
    service.dispose(); ad.emit('earned');
    expect((await operation).code).toBe('disposed');
    expect(reward).not.toHaveBeenCalled();
    expect(vi.getTimerCount()).toBe(0);
  });
});

describe('interstitial placement and frequency', () => {
  beforeEach(() => { vi.useFakeTimers(); vi.setSystemTime(0); });
  afterEach(() => { vi.clearAllTimers(); vi.useRealTimers(); });

  it('places journey interstitials only after every third completed level with cooldowns', async () => {
    const { service, current } = setup();
    await service.initializeAfterConsent();
    await vi.advanceTimersByTimeAsync(121_000);
    for (const level of [0, 1, 2, 4, 5, 7, 8, 10]) {
      expect((await service.showInterstitialAtNaturalBreak({ atResults: true, level })).code).toBe('frequency_cap');
    }
    const ad = current('interstitial');
    const shown = service.showInterstitialAtNaturalBreak({ atResults: true, level: 3 });
    ad.emit('closed');
    expect((await shown).code).toBe('shown');
    expect((await service.showInterstitialAtNaturalBreak({ atResults: true, level: 6 })).code).toBe('frequency_cap');
    service.dispose();
  });

  it('requires results, over 120 seconds and at least three completed rounds', async () => {
    const { service, current } = setup();
    await service.initializeAfterConsent();
    expect((await service.showInterstitialAtNaturalBreak({ atResults: false })).code).toBe('invalid_transition');
    service.roundCompleted(); service.roundCompleted(); service.roundCompleted();
    expect((await service.showInterstitialAtNaturalBreak({ atResults: true })).code).toBe('frequency_cap');
    await vi.advanceTimersByTimeAsync(120_000);
    expect((await service.showInterstitialAtNaturalBreak({ atResults: true })).code).toBe('frequency_cap');
    await vi.advanceTimersByTimeAsync(1);
    const ad = current('interstitial');
    const operation = service.showInterstitialAtNaturalBreak({ atResults: true });
    ad.emit('closed');
    expect((await operation).code).toBe('shown');
    service.dispose();
  });

  it('elapsed time alone cannot bypass three-round minimum', async () => {
    const { service } = setup();
    await service.initializeAfterConsent();
    await vi.advanceTimersByTimeAsync(121_000);
    service.roundCompleted(); service.roundCompleted();
    expect((await service.showInterstitialAtNaturalBreak({ atResults: true })).code).toBe('frequency_cap');
    service.dispose();
  });

  it('rewarded ads reset full-screen cooldown starting at dismissal', async () => {
    const { service, current } = setup();
    await service.initializeAfterConsent();
    service.roundCompleted(); service.roundCompleted(); service.roundCompleted();
    await vi.advanceTimersByTimeAsync(121_000);
    const ad = current('rewarded');
    const reward = service.showRewardedIfReady(vi.fn());
    await vi.advanceTimersByTimeAsync(40_000);
    ad.emit('closed'); await reward;
    await vi.advanceTimersByTimeAsync(179_999);
    expect((await service.showInterstitialAtNaturalBreak({ atResults: true })).code).toBe('frequency_cap');
    await vi.advanceTimersByTimeAsync(1);
    const interstitial = current('interstitial');
    const operation = service.showInterstitialAtNaturalBreak({ atResults: true });
    interstitial.emit('closed');
    expect((await operation).code).toBe('shown');
    service.dispose();
  });

  it('never repeats an interstitial on the same results transition', async () => {
    const { service, current } = setup();
    await service.initializeAfterConsent();
    service.roundCompleted(); service.roundCompleted(); service.roundCompleted();
    await vi.advanceTimersByTimeAsync(121_000);
    const ad = current('interstitial');
    const operation = service.showInterstitialAtNaturalBreak({ atResults: true });
    ad.emit('closed'); await operation;
    await vi.advanceTimersByTimeAsync(180_000);
    expect((await service.showInterstitialAtNaturalBreak({ atResults: true })).code).toBe('frequency_cap');
    service.roundCompleted();
    expect((await service.showInterstitialAtNaturalBreak({ atResults: true })).code).toBe('frequency_cap');
    service.roundCompleted(); service.roundCompleted();
    const next = current('interstitial');
    const second = service.showInterstitialAtNaturalBreak({ atResults: true });
    next.emit('closed');
    expect((await second).code).toBe('shown');
    service.dispose();
  });
});
