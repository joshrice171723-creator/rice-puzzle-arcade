export type AdFormat = 'rewarded' | 'interstitial';
export type AdCode = 'ready' | 'shown' | 'rewarded' | 'closed' | 'not_ready' | 'consent_required' | 'busy' | 'frequency_cap' | 'invalid_transition' | 'failed' | 'timeout' | 'disposed' | 'unsupported';
export type AdResult = { code: AdCode; earned: boolean };
export type ConsentInfo = { canRequestAds: boolean; privacyOptionsRequired: boolean };
export type AdEvent = 'loaded' | 'opened' | 'closed' | 'earned' | 'error';
export interface AdHandle {
  on(event: AdEvent, callback: () => void): () => void;
  load(): void;
  show(): Promise<unknown>;
  destroy(): void;
}
export interface AdsAdapter {
  supported: boolean;
  gatherConsent(): Promise<ConsentInfo>;
  privacyOptions(): Promise<ConsentInfo>;
  initialize(): Promise<unknown>;
  create(format: AdFormat): AdHandle;
  isForeground(): boolean;
}
export interface AdsState {
  initialized: boolean;
  busy: boolean;
  consentAllowed: boolean;
  privacyOptionsRequired: boolean;
  lastResult: AdCode;
}
type Slot = { handle: AdHandle; readyAt: number | null; cleanup: (() => void)[]; timer: ReturnType<typeof setTimeout> };

/** The game engines never receive ad inventory, consent, pricing, or history. */
export class AdsService {
  private state: AdsState = { initialized: false, busy: false, consentAllowed: false, privacyOptionsRequired: false, lastResult: 'not_ready' };
  private listeners = new Set<(state: AdsState) => void>();
  private slots: Partial<Record<AdFormat, Slot>> = {};
  private startedAt: number;
  private lastFullscreen = -Infinity;
  private rounds = 0;
  private lastInterstitialRound = -1;
  private disposed = false;
  private quarantined = false;
  private initialization: Promise<AdResult> | null = null;
  private cancelShow: (() => void) | null = null;
  private showingFormat: AdFormat | null = null;

  constructor(private adapter: AdsAdapter, private now: () => number = Date.now) {
    this.startedAt = now();
  }

  getState = (): AdsState => ({ ...this.state });

  subscribe = (listener: (state: AdsState) => void): (() => void) => {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  };

  private update(patch: Partial<AdsState>) {
    this.state = { ...this.state, ...patch };
    for (const listener of this.listeners) listener(this.getState());
  }

  private result(code: AdCode, earned = false): AdResult {
    if (!this.disposed) this.update({ lastResult: code });
    return { code, earned };
  }

  private async deadline<T>(operation: Promise<T>, ms: number): Promise<T> {
    let timer: ReturnType<typeof setTimeout> | undefined;
    try {
      return await Promise.race([operation, new Promise<never>((_, reject) => {
        timer = setTimeout(() => reject(new Error('timeout')), ms);
      })]);
    } finally {
      if (timer) clearTimeout(timer);
    }
  }

  initializeAfterConsent = (): Promise<AdResult> => {
    if (this.disposed) return Promise.resolve(this.result('disposed'));
    if (!this.adapter.supported) return Promise.resolve(this.result('unsupported'));
    if (this.initialization) return this.initialization;
    if (this.state.initialized && this.state.consentAllowed) return Promise.resolve(this.result('ready'));
    this.initialization = this.configure(false).finally(() => { this.initialization = null; });
    return this.initialization;
  };

  private async configure(privacy: boolean): Promise<AdResult> {
    this.update({ busy: true, consentAllowed: false });
    this.clearSlots();
    try {
      const consent = await this.deadline(privacy ? this.adapter.privacyOptions() : this.adapter.gatherConsent(), 30_000);
      if (this.disposed) return this.result('disposed');
      this.update({ consentAllowed: consent.canRequestAds, privacyOptionsRequired: consent.privacyOptionsRequired });
      if (!consent.canRequestAds) return this.result('consent_required');
      if (!this.state.initialized) await this.deadline(this.adapter.initialize(), 15_000);
      if (this.disposed) return this.result('disposed');
      this.update({ initialized: true });
      this.preload();
      return this.result('ready');
    } catch (error) {
      this.update({ consentAllowed: false });
      return this.result(error instanceof Error && error.message === 'timeout' ? 'timeout' : 'failed');
    } finally {
      if (!this.disposed) this.update({ busy: false });
    }
  }

  showPrivacyOptions = (): Promise<AdResult> => {
    if (this.disposed) return Promise.resolve(this.result('disposed'));
    if (!this.adapter.supported) return Promise.resolve(this.result('unsupported'));
    if (this.state.busy || this.initialization) return Promise.resolve(this.result('busy'));
    this.initialization = this.configure(true).finally(() => { this.initialization = null; });
    return this.initialization;
  };

  private clearSlot(format: AdFormat) {
    const slot = this.slots[format];
    if (!slot) return;
    delete this.slots[format];
    clearTimeout(slot.timer);
    slot.cleanup.forEach(unsubscribe => unsubscribe());
    slot.handle.destroy();
  }

  private clearSlots() {
    this.clearSlot('rewarded');
    this.clearSlot('interstitial');
  }

  preload = (): void => {
    if (this.disposed || this.quarantined || !this.state.initialized || !this.state.consentAllowed) return;
    for (const format of ['rewarded', 'interstitial'] as const) {
      const existing = this.slots[format];
      if (existing && (existing.readyAt === null || this.now() - existing.readyAt < 55 * 60_000)) continue;
      this.clearSlot(format);
      try {
        const handle = this.adapter.create(format);
        const slot: Slot = { handle, readyAt: null, cleanup: [], timer: setTimeout(() => {
          this.clearSlot(format);
          this.result('timeout');
        }, 15_000) };
        this.slots[format] = slot;
        slot.cleanup.push(handle.on('loaded', () => {
          if (this.slots[format] !== slot) return;
          clearTimeout(slot.timer);
          slot.readyAt = this.now();
          this.update({});
        }), handle.on('error', () => {
          if (this.slots[format] !== slot || this.showingFormat === format) return;
          this.clearSlot(format);
          this.result('failed');
        }));
        handle.load();
      } catch {
        this.clearSlot(format);
        this.result('failed');
      }
    }
  };

  isReady = (format: AdFormat): boolean => {
    const slot = this.slots[format];
    return !this.disposed && !this.quarantined && this.state.initialized && this.state.consentAllowed &&
      !!slot && slot.readyAt !== null && this.now() - slot.readyAt < 55 * 60_000;
  };

  roundCompleted = (): void => { if (!this.disposed) this.rounds++; };

  showRewardedIfReady = (onRewardEarned: () => void): Promise<AdResult> => this.show('rewarded', onRewardEarned);

  showInterstitialAtNaturalBreak = ({ atResults, level }: { atResults: boolean; level?: number }): Promise<AdResult> => {
    if (!atResults) return Promise.resolve(this.result('invalid_transition'));
    if (this.now() - this.startedAt <= 120_000 || (level === undefined ? this.rounds < 3 || this.rounds % 3 !== 0 : !Number.isInteger(level) || level < 1 || level % 3 !== 0) ||
      this.now() - this.lastFullscreen < 180_000 || this.lastInterstitialRound === this.rounds) {
      return Promise.resolve(this.result('frequency_cap'));
    }
    return this.show('interstitial');
  };

  private show(format: AdFormat, onRewardEarned?: () => void): Promise<AdResult> {
    if (this.disposed) return Promise.resolve(this.result('disposed'));
    if (!this.adapter.supported) return Promise.resolve(this.result('unsupported'));
    if (this.state.busy) return Promise.resolve(this.result('busy'));
    if (!this.state.consentAllowed) return Promise.resolve(this.result('consent_required'));
    if (!this.adapter.isForeground()) return Promise.resolve(this.result('invalid_transition'));
    if (!this.isReady(format)) { this.preload(); return Promise.resolve(this.result('not_ready')); }
    const slot = this.slots[format]!;
    this.showingFormat = format;
    slot.readyAt = null;
    if (format === 'interstitial') this.lastInterstitialRound = this.rounds;
    // Reserving the cooldown before the native call prevents races and is conservative on SDK failures.
    this.lastFullscreen = this.now();
    this.update({ busy: true });
    return new Promise<AdResult>(resolve => {
      let earned = false;
      let finished = false;
      let opened = false;
      const finish = (code: AdCode) => {
        if (finished) return;
        finished = true;
        clearTimeout(timer);
        this.cancelShow = null;
        this.showingFormat = null;
        this.clearSlot(format);
        if (!this.disposed) {
          this.update({ busy: false });
          this.preload();
        }
        resolve(this.result(code, earned));
      };
      const timer = setTimeout(() => {
        // A missing native dismissal leaves its actual UI state unknown: disable further ads this session.
        this.quarantined = true;
        finish('timeout');
      }, 180_000);
      this.cancelShow = () => finish('disposed');
      slot.cleanup.push(slot.handle.on('opened', () => { opened = true; }),
        slot.handle.on('earned', () => {
          if (format !== 'rewarded' || earned || finished || this.disposed) return;
          earned = true;
          try { onRewardEarned?.(); } catch { /* A caller failure cannot grant the same reward again. */ }
        }),
        slot.handle.on('closed', () => {
          this.lastFullscreen = this.now();
          finish(earned ? 'rewarded' : format === 'rewarded' ? 'closed' : opened ? 'shown' : 'closed');
        }), slot.handle.on('error', () => finish('failed')));
      try { slot.handle.show().catch(() => finish('failed')); } catch { finish('failed'); }
    });
  }

  dispose = (): void => {
    this.disposed = true;
    this.cancelShow?.();
    this.clearSlots();
    this.listeners.clear();
  };
}
