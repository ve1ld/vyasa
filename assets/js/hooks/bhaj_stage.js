const ARC_CIRC     = 113.1;    // 2π × 18px
const MIN_PERIOD   = 500;      // ms
const MAX_PERIOD   = 30_000;   // ms — ignore taps further apart
const MAX_OFF_FRAC = 0.6;
const OFFSET_STEP  = 250;
const HUD_ID       = 'ks-hud';

// ── Inject HUD styles once ────────────────────────────────────────────────────
//
// Keeps all transition/animation logic in CSS where it belongs, so JS only
// toggles semantic state classes.  Injected lazily so SSR pages don't flash.
//
function injectHUDStyles() {
    if (document.getElementById('ks-hud-styles')) return;
    const s = document.createElement('style');
    s.id = 'ks-hud-styles';
    s.textContent = `
      /* ── Collapsible panel ── */
      #ks-hud-collapsible {
        max-width: 0;
        opacity: 0;
        overflow: hidden;
        pointer-events: none;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        white-space: nowrap;
        transition:
          max-width 0.30s cubic-bezier(0.34, 1.06, 0.64, 1),
          opacity   0.22s ease;
      }
      /* Expand on desktop hover OR explicit .ks-open class (touch toggle) */
      #ks-hud:hover  #ks-hud-collapsible,
      #ks-hud.ks-open #ks-hud-collapsible {
        max-width: 340px;
        opacity: 1;
        pointer-events: auto;
      }

      /* ── Mini tempo badge under circle (hides on expand) ── */
      #ks-mini-tempo {
        opacity: 0;
        transform: translateY(2px);
        transition: opacity 0.25s ease, transform 0.25s ease;
      }
      #ks-mini-tempo.ks-visible {
        opacity: 1;
        transform: translateY(2px);
        transform: translateX(15px);
      }
      #ks-hud:hover  #ks-mini-tempo,
      #ks-hud.ks-open #ks-mini-tempo {
        opacity: 0 !important;
        transform: translateY(2px) !important;
      }

      /* ── Lock dot: pulse when running ── */
      @keyframes ks-pulse {
        0%, 100% { box-shadow: 0 0  6px rgba(255,153,51,0.65); }
        50%       { box-shadow: 0 0 14px rgba(255,153,51,0.95); }
      }
      #ks-lock.ks-running {
        animation: ks-pulse 1.8s ease-in-out infinite;
      }

      /* ── Tap-ring ripple on the arc button ── */
      @keyframes ks-tapring {
        0%   { opacity: 0.55; transform: scale(0.95); }
        100% { opacity: 0;    transform: scale(1.65); }
      }
      .ks-tapring {
        position: absolute; inset: 0;
        border-radius: 9999px;
        border: 1.5px solid #ff9933;
        pointer-events: none;
        animation: ks-tapring 0.4s ease-out forwards;
      }

      /* ── Touch expand hint (fades out after first open) ── */
      @keyframes ks-hint-fade {
        0%   { opacity: 0.55; transform: translateX(0); }
        60%  { opacity: 0.55; transform: translateX(-4px); }
        100% { opacity: 0;    transform: translateX(-4px); }
      }
      #ks-hint { animation: ks-hint-fade 1.8s ease-out 1.2s both; pointer-events: none; }
    `;
    document.head.appendChild(s);
}

// ── HUD portal ────────────────────────────────────────────────────────────────
function buildHUD() {
    injectHUDStyles();

    const el = document.createElement('div');
    el.id = HUD_ID;
    // Anchored bottom-right; flex is reversed so the circle is always rightmost
    el.className = [
        'fixed bottom-8 right-5 z-[9000]',
        'flex flex-row-reverse items-center gap-2 px-2.5 py-2',
        'bg-black/45 backdrop-blur-xs',
        'border border-amber-900/25 rounded-full',
        // 'shadow-[0_4px_32px_rgba(0,0,0,0.70)]',
        'select-none whitespace-nowrap cursor-default',
        'transition-[padding] duration-200',
    ].join(' ');

    el.innerHTML = `
      <!-- ══ Always-visible: circle + lock dot (right anchor) ═══════════════ -->
      <div class="flex flex-row-reverse items-center gap-2 flex-shrink-0">

        <!-- Lock dot — glows/pulses when running, dims when paused -->
        <div id="ks-lock"
             class="w-1.5 h-1.5 rounded-full bg-amber-900/25 flex-shrink-0
                    transition-[background] duration-300">
        </div>

        <!-- Arc tap button -->
        <div class="relative flex-shrink-0">
          <button id="ks-next"
            class="relative w-11 h-11 flex items-center justify-center
                   bg-transparent border-none rounded-full cursor-pointer
                   transition-colors duration-150
                   hover:bg-amber-900/10 active:bg-amber-900/20">
            <svg id="ks-arc-svg"
                 class="absolute inset-0 w-full h-full -rotate-90 overflow-visible"
                 viewBox="0 0 44 44" aria-hidden="true">
              <circle class="fill-none stroke-amber-900/20 stroke-[2.5]"
                      cx="22" cy="22" r="18"/>
              <circle id="ks-arc-fill"
                      class="fill-none stroke-[#ff9933] stroke-[2.5] [stroke-linecap:round]"
                      cx="22" cy="22" r="18"
                      style="stroke-dasharray:${ARC_CIRC};stroke-dashoffset:${ARC_CIRC}"/>
            </svg>
            <span id="ks-arc-icon"
                  class="relative z-10 text-amber-600/65 text-base leading-none
                         pointer-events-none transition-[color,transform] duration-150">›</span>
          </button>

          <!-- Mini tempo: visible only when collapsed & tempo is set -->
          <span id="ks-mini-tempo"
                class="absolute -bottom-1 left-1/2 -translate-x-1/2
                       text-[0.40rem] text-[#ff9933]/60 leading-none
                       pointer-events-none whitespace-nowrap">
          </span>

          <!-- Touch-expand hint arrow (auto-fades) -->
          <span id="ks-hint"
                class="absolute top-1/2 -left-4 -translate-y-1/2
                       text-amber-700/35 text-[0.6rem] leading-none
                       pointer-events-none hidden">‹</span>
        </div>
      </div>

      <!-- ══ Collapsible left panel ═══════════════════════════════════════════ -->
      <div id="ks-hud-collapsible">

        <!-- Offset nudge -->
        <div class="flex items-center gap-1">
          <button id="ks-off-minus"
                  class="text-amber-800/45 text-base leading-none px-1 py-0.5 rounded
                         bg-transparent border-none cursor-pointer
                         transition-colors duration-150
                         hover:text-[#FF9B6D] hover:bg-amber-900/10">−</button>
          <span id="ks-offset-val"
                class="text-[0.62rem] text-amber-800/45 min-w-[38px] text-center
                       tracking-wide cursor-pointer transition-colors duration-200
                       hover:text-[#FF9B6D]">0 ms</span>
          <button id="ks-off-plus"
                  class="text-amber-800/45 text-base leading-none px-1 py-0.5 rounded
                         bg-transparent border-none cursor-pointer
                         transition-colors duration-150
                         hover:text-[#FF9B6D] hover:bg-amber-900/10">+</button>
        </div>

        <div class="w-px h-5 bg-amber-900/20 flex-shrink-0"></div>

        <!-- Tempo readout — click to edit manually -->
        <div class="flex flex-col items-center min-w-[44px] relative">
          <span id="ks-tempo-val"
                title="Click to set tempo manually"
                class="text-[1rem] text-amber-900/35 leading-none tracking-wide
                       transition-colors duration-300 cursor-text">—</span>
          <input id="ks-tempo-input"
                 type="text" inputmode="decimal" placeholder="s"
                 class="hidden absolute top-0 left-0 text-[1rem] leading-none
                        text-amber-600 tracking-wide bg-transparent
                        border-b border-amber-600/60 outline-none text-center
                        placeholder:text-amber-900/25"
                 style="width:80px"/>
          <span class="text-[0.42rem] uppercase text-amber-900/35 mt-0.5">sec / verse</span>
        </div>

        <div class="w-px h-5 bg-amber-900/20 flex-shrink-0"></div>

        <!-- Reset -->
        <button id="ks-reset"
              title="Reset all (r)"
              class="text-amber-800/40 text-[0.65rem] tracking-widest uppercase
                     px-1 py-1.5 rounded-full bg-transparent cursor-pointer
                     transition-all duration-150
                     hover:text-red-400/80 hover:bg-red-900/10 active:bg-red-900/20">↺</button>
      </div>
    `;
    return el;
}

// ── Hook ──────────────────────────────────────────────────────────────────────
const BhajStage = {
    mounted() {
        this._period           = 0;
        this._offsetMs         = 0;
        this._lastTap          = null;
        this._running          = false;
        this._paused           = false;
        this._remainingMs      = 0;
        this._pausedArcFrac    = 0;
        this._timerStartedAt   = 0;
        this._timerEffective   = 0;
        this._timer            = null;
        this._raf              = null;
        this._scrollRaf        = null;
        this._scrollAbort      = null;
        this._active           = null;
        this._verseObserver    = null;
        this._hudExpanded      = false;   // touch-toggle state
        this._touchCollapseTimer = null;  // auto-collapse on touch
        this._mountHUD();
        this._bindHUD();
        this._bindSeekBtns();
        this._bindWindowEvents();
        this._bindKeyboard();
        this._bindVerseObserver();
        requestAnimationFrame(() => {
            const first = this._verses()[0];
            if (first) this._focusEl(first);
        });
    },
    updated() {
        this._bindSeekBtns();
        this._verses().forEach(v => this._verseObserver?.observe(v));
        if (this._active && !document.contains(this._active)) {
            const first = this._verses()[0];
            if (first) this._focusEl(first);
        }
    },
    destroyed() {
        this._stopTimer();
        clearTimeout(this._touchCollapseTimer);
        if (this._scrollRaf)   cancelAnimationFrame(this._scrollRaf);
        if (this._scrollAbort) this._scrollAbort();
        this._verseObserver?.disconnect();
        document.getElementById(HUD_ID)?.remove();
        window.removeEventListener('phx:verseEmphasis',      this._onEmphasis);
        window.removeEventListener('phx:verseEmphasisReset', this._onReset);
        document.removeEventListener('keydown',              this._onKey);
    },

    // ── Verse index ──────────────────────────────────────────────────────────
    _verses() {
        return Array.from(
            this.el.querySelectorAll('#karoke-stream [data-verse-id]')
        );
    },
    _indexOf(el) {
        return this._verses().indexOf(el);
    },

    // ── Follow-spot ──────────────────────────────────────────────────────────
    _applyFollowSpot(activeEl) {
        const all = this._verses();
        const idx = all.indexOf(activeEl);
        all.forEach((w, i) => {
            const delta = i - idx;
            w.dataset.stage =
                delta === -1 ? 'active'  :
                delta ===  0 ? 'active'  :
                delta === +1 ? 'active'  :
                delta === +2 ? 'upcoming':
                delta === -2 ? 'prev'    :
                delta === -3 ? 'prev'    : 'umbra';
        });
    },
    _focusEl(el, scroll = true) {
        this._applyFollowSpot(el);
        if (scroll) this._scrollToCenter(el);
        this._active = el;
    },

    // ── Buttery centered scroll ───────────────────────────────────────────────
    _scrollToCenter(el) {
        if (this._scrollRaf)   { cancelAnimationFrame(this._scrollRaf); this._scrollRaf = null; }
        if (this._scrollAbort) { this._scrollAbort(); this._scrollAbort = null; }

        const scrollEl      = this._scrollContainer();
        const rect          = el.getBoundingClientRect();
        const containerRect = scrollEl === window
            ? { top: 0, height: window.innerHeight }
            : scrollEl.getBoundingClientRect();

        const elMid    = rect.top + rect.height / 2;
        const vpMid    = containerRect.top + containerRect.height / 2;
        const delta    = elMid - vpMid;
        const startY   = scrollEl === window ? window.scrollY : scrollEl.scrollTop;
        const endY     = startY + delta;

        if (Math.abs(delta) < 2) return;

        const duration     = Math.min(520, Math.max(280, Math.abs(delta) * 0.55));
        const easeOutCubic = t => 1 - Math.pow(1 - t, 3);

        const t0 = performance.now();
        const doScroll = (now) => {
            const t = Math.min((now - t0) / duration, 1);
            const y = startY + delta * easeOutCubic(t);
            scrollEl === window ? window.scrollTo(0, y) : (scrollEl.scrollTop = y);
            if (t < 1) {
                this._scrollRaf = requestAnimationFrame(doScroll);
            } else {
                this._scrollRaf = null;
                this._scrollAbort = null;
                window.removeEventListener('wheel',     abort, { passive: true });
                window.removeEventListener('touchmove', abort, { passive: true });
            }
        };

        const abort = () => {
            if (this._scrollRaf) { cancelAnimationFrame(this._scrollRaf); this._scrollRaf = null; }
            this._scrollAbort = null;
            window.removeEventListener('wheel',     abort, { passive: true });
            window.removeEventListener('touchmove', abort, { passive: true });
        };
        this._scrollAbort = abort;
        window.addEventListener('wheel',     abort, { passive: true });
        window.addEventListener('touchmove', abort, { passive: true });

        this._scrollRaf = requestAnimationFrame(doScroll);
    },
    _scrollContainer() {
        let node = this.el.parentElement;
        while (node && node !== document.body) {
            const style    = window.getComputedStyle(node);
            const overflow = style.overflowY;
            if (overflow === 'scroll' || overflow === 'auto') return node;
            node = node.parentElement;
        }
        return window;
    },
    _focusById(id) {
        const el = this.el.querySelector(`[data-verse-id="${CSS.escape(id)}"]`);
        if (el) this._focusEl(el);
    },

    // ── Navigation ───────────────────────────────────────────────────────────
    _advance() {
        const v = this._verses();
        if (!v.length) return;
        const next = v[(this._indexOf(this._active) + 2) % v.length];
        this._focusEl(next);
    },
    _retreat() {
        const v = this._verses();
        if (!v.length) return;
        const prev = v[(this._indexOf(this._active) - 1 + v.length) % v.length];
        this._focusEl(prev);
    },

    // ── Tempo tap ────────────────────────────────────────────────────────────
    _tap() {
        const now = performance.now();
        this._tapFlash();
        this._advance();
        if (this._lastTap !== null) {
            const delta = now - this._lastTap;
            if (delta >= MIN_PERIOD && delta <= MAX_PERIOD) {
                this._period   = delta;
                this._offsetMs = this._clampOffset(this._offsetMs);
                this._startTimer();
                this._renderHUD();
            }
        }
        this._lastTap = now;
    },

    // ── Timer ────────────────────────────────────────────────────────────────
    _startTimer(firstInterval) {
        this._stopTimerInternal();
        this._running        = true;
        this._paused         = false;
        const effective      = firstInterval ?? Math.max(this._period + this._offsetMs, MIN_PERIOD);
        this._timerEffective = effective;
        this._timerStartedAt = performance.now();
        this._timer = setTimeout(() => {
            if (!this._running) return;
            this._advance();
            this._lastTap = performance.now();
            this._startTimer();
        }, effective);
        this._startArc(effective);
        this._setLocked('running');
        const icon = document.getElementById('ks-arc-icon');
        if (icon) icon.textContent = '⏸';
    },

    _pauseTimer() {
        if (!this._running) return;
        const elapsed        = performance.now() - this._timerStartedAt;
        this._remainingMs    = Math.max(0, this._timerEffective - elapsed);
        this._pausedArcFrac  = Math.min(elapsed / this._timerEffective, 1);
        this._offsetMs       = this._clampOffset(this._offsetMs + this._remainingMs);
        this._stopTimerInternal();
        this._paused = true;
        const arcEl = document.getElementById('ks-arc-fill');
        if (arcEl) arcEl.style.strokeDashoffset = (ARC_CIRC * (1 - this._pausedArcFrac)).toFixed(2);
        this._setLocked('paused');
        const icon = document.getElementById('ks-arc-icon');
        if (icon) icon.textContent = '▶';
        this._renderHUD();
    },

    _resumeTimer() {
        if (!this._paused) return;
        this._paused = false;
        this._startTimer(Math.max(this._remainingMs, MIN_PERIOD));
        this._resumeArc(Math.max(this._remainingMs, MIN_PERIOD), this._pausedArcFrac);
    },

    _stopTimerInternal() {
        this._running = false;
        clearTimeout(this._timer);
        this._timer = null;
        cancelAnimationFrame(this._raf);
        this._raf = null;
    },

    _stopTimer() {
        this._stopTimerInternal();
        this._paused      = false;
        this._remainingMs = 0;
        this._setLocked('off');
        const icon = document.getElementById('ks-arc-icon');
        if (icon) icon.textContent = '›';
        this._arcIdle();
    },

    // ── Hard reset ───────────────────────────────────────────────────────────
    _hardReset() {
        this._stopTimerInternal();
        clearTimeout(this._touchCollapseTimer);
        if (this._scrollRaf)   { cancelAnimationFrame(this._scrollRaf); this._scrollRaf = null; }
        if (this._scrollAbort) { this._scrollAbort(); this._scrollAbort = null; }
        this._paused         = false;
        this._running        = false;
        this._period         = 0;
        this._offsetMs       = 0;
        this._lastTap        = null;
        this._remainingMs    = 0;
        this._pausedArcFrac  = 0;
        this._timerStartedAt = 0;
        this._timerEffective = 0;
        this._active         = null;

        this._cancelTempoEdit();
        this._setLocked('off');
        this._arcIdle();

        const icon = document.getElementById('ks-arc-icon');
        if (icon) icon.textContent = '›';

        this._renderHUD();

        const btn = document.getElementById('ks-reset');
        if (btn) {
            btn.classList.add('text-red-400/80');
            setTimeout(() => btn.classList.remove('text-red-400/80'), 400);
        }
    },

    // ── Arc ──────────────────────────────────────────────────────────────────
    _startArc(duration) { this._resumeArc(duration, 0); },
    _resumeArc(duration, startFrac = 0) {
        cancelAnimationFrame(this._raf);
        const arcEl = document.getElementById('ks-arc-fill');
        if (!arcEl) return;
        const t0   = performance.now();
        const tick = (now) => {
            if (!this._running) return;
            const p = Math.min(startFrac + (now - t0) / duration, 1);
            arcEl.style.strokeDashoffset = (ARC_CIRC * (1 - p)).toFixed(2);
            if (p < 1) this._raf = requestAnimationFrame(tick);
        };
        this._raf = requestAnimationFrame(tick);
    },
    _arcIdle() {
        cancelAnimationFrame(this._raf);
        const arcEl = document.getElementById('ks-arc-fill');
        if (arcEl) arcEl.style.strokeDashoffset = ARC_CIRC;
    },

    // ── Lock dot ─────────────────────────────────────────────────────────────
    _setLocked(state) {
        const dot = document.getElementById('ks-lock');
        if (!dot) return;
        dot.style.boxShadow = '';
        dot.classList.remove('bg-[#ff9933]', 'bg-amber-500/50', 'bg-amber-900/25', 'ks-running');
        if (state === 'running') {
            dot.classList.add('bg-[#ff9933]', 'ks-running');
        } else if (state === 'paused') {
            dot.classList.add('bg-amber-500/50');
            dot.style.boxShadow = '0 0 4px rgba(255,153,51,0.30)';
        } else {
            dot.classList.add('bg-amber-900/25');
        }
    },

    // ── Offset ───────────────────────────────────────────────────────────────
    _nudgeOffset(delta) {
        this._offsetMs = this._clampOffset(this._offsetMs + delta);
        this._renderHUD();
    },
    _resetOffset() {
        this._offsetMs = 0;
        this._renderHUD();
        if (this._running) this._startTimer();
    },
    _clampOffset(v) {
        if (this._period <= 0) return v;
        const cap = Math.floor(this._period * MAX_OFF_FRAC);
        return Math.max(-cap, Math.min(cap, v));
    },

    // ── HUD render ───────────────────────────────────────────────────────────
    _renderHUD() {
        const tEl    = document.getElementById('ks-tempo-val');
        const oEl    = document.getElementById('ks-offset-val');
        const miniEl = document.getElementById('ks-mini-tempo');
        if (!tEl || !oEl) return;

        if (this._period > 0) {
            const display = ((this._period + this._offsetMs) / 1000).toFixed(1) + 's';
            tEl.textContent   = display;
            tEl.style.color   = '#ff9933';
            tEl.style.opacity = '0.90';
            // Mini badge: tempo visible at a glance when HUD is collapsed
            if (miniEl) {
                miniEl.textContent = display;
                miniEl.classList.add('ks-visible');
            }
        } else {
            tEl.textContent   = '—';
            tEl.style.color   = '';
            tEl.style.opacity = '';
            if (miniEl) miniEl.classList.remove('ks-visible');
        }
        const sign = this._offsetMs > 0 ? '+' : '';
        oEl.textContent = `${sign}${this._offsetMs} ms`;
    },

    // ── Tap flash (ripple ring) ───────────────────────────────────────────────
    _tapFlash() {
        const btn = document.getElementById('ks-next');
        if (!btn) return;
        // Remove any existing ring first
        btn.querySelectorAll('.ks-tapring').forEach(r => r.remove());
        const ring = document.createElement('span');
        ring.className = 'ks-tapring';
        btn.appendChild(ring);
        ring.addEventListener('animationend', () => ring.remove(), { once: true });
    },

    // ── Touch expand/collapse toggle ──────────────────────────────────────────
    //
    // Desktop: CSS :hover handles expansion — no JS needed.
    // Touch:   first tap outside the circle opens the panel; it auto-collapses
    //          after 4 s of inactivity so the HUD stays tidy mid-performance.
    //
    _openHUD() {
        const hud = document.getElementById(HUD_ID);
        if (!hud) return;
        hud.classList.add('ks-open');
        this._hudExpanded = true;
        this._scheduleAutoCollapse();
        // Show the hint arrow once, then it fades via CSS
        const hint = document.getElementById('ks-hint');
        if (hint) hint.classList.remove('hidden');
    },
    _closeHUD() {
        const hud = document.getElementById(HUD_ID);
        if (!hud) return;
        hud.classList.remove('ks-open');
        this._hudExpanded = false;
        clearTimeout(this._touchCollapseTimer);
    },
    _scheduleAutoCollapse() {
        clearTimeout(this._touchCollapseTimer);
        this._touchCollapseTimer = setTimeout(() => this._closeHUD(), 4000);
    },

    // ── Tempo manual edit ────────────────────────────────────────────────────
    _openTempoEdit() {
        const valEl   = document.getElementById('ks-tempo-val');
        const inputEl = document.getElementById('ks-tempo-input');
        if (!valEl || !inputEl) return;
        inputEl.value = this._period > 0
            ? ((this._period + this._offsetMs) / 1000).toFixed(1)
            : '';
        valEl.classList.add('invisible');
        inputEl.classList.remove('hidden');
        inputEl.focus();
        inputEl.select();
    },
    _commitTempoEdit() {
        const valEl   = document.getElementById('ks-tempo-val');
        const inputEl = document.getElementById('ks-tempo-input');
        if (!valEl || !inputEl) return;
        const raw = parseFloat(inputEl.value);
        if (!isNaN(raw) && raw > 0) {
            const ms     = Math.min(Math.max(raw * 1000, MIN_PERIOD), MAX_PERIOD);
            this._period   = ms - this._offsetMs;
            this._offsetMs = this._clampOffset(this._offsetMs);
            this._lastTap  = performance.now();
            this._renderHUD();
            if (this._running || this._paused) this._startTimer();
        }
        inputEl.classList.add('hidden');
        valEl.classList.remove('invisible');
    },
    _cancelTempoEdit() {
        const valEl   = document.getElementById('ks-tempo-val');
        const inputEl = document.getElementById('ks-tempo-input');
        if (!inputEl || !valEl) return;
        inputEl.classList.add('hidden');
        valEl.classList.remove('invisible');
    },

    // ── Verse focus via IntersectionObserver ─────────────────────────────────
    _bindVerseObserver() {
        this._verseObserver = new IntersectionObserver(
            (entries) => {
                if (this._running) return;
                let best = null, bestRatio = 0;
                entries.forEach(entry => {
                    if (entry.isIntersecting && entry.intersectionRatio > bestRatio) {
                        bestRatio = entry.intersectionRatio;
                        best = entry.target;
                    }
                });
                if (best && best !== this._active) {
                    this._applyFollowSpot(best);
                    this._active = best;
                }
            },
            { rootMargin: '-45% 0px -45% 0px', threshold: 0 }
        );
        this._verses().forEach(v => this._verseObserver.observe(v));
    },

    // ── Mount / bind ─────────────────────────────────────────────────────────
    _mountHUD() {
        if (document.getElementById(HUD_ID)) return;
        document.body.appendChild(buildHUD());
    },
    _bindHUD() {
        // Primary tap/advance
        document.getElementById('ks-next')
            ?.addEventListener('click', () => {
                this._tap();
                // Reset auto-collapse timer if HUD is touch-expanded
                if (this._hudExpanded) this._scheduleAutoCollapse();
            });

        // Offset
        document.getElementById('ks-off-minus')
            ?.addEventListener('click', () => {
                this._nudgeOffset(-OFFSET_STEP);
                if (this._hudExpanded) this._scheduleAutoCollapse();
            });
        document.getElementById('ks-off-plus')
            ?.addEventListener('click', () => {
                this._nudgeOffset(+OFFSET_STEP);
                if (this._hudExpanded) this._scheduleAutoCollapse();
            });
        document.getElementById('ks-offset-val')
            ?.addEventListener('click', () => this._resetOffset());

        // Hard reset
        document.getElementById('ks-reset')
            ?.addEventListener('click', () => this._hardReset());

        // Tempo manual edit
        document.getElementById('ks-tempo-val')
            ?.addEventListener('click', () => this._openTempoEdit());

        const inputEl = document.getElementById('ks-tempo-input');
        if (inputEl) {
            inputEl.addEventListener('keydown', (e) => {
                if (e.key === 'Enter')  { e.preventDefault(); this._commitTempoEdit(); }
                if (e.key === 'Escape') { e.preventDefault(); this._cancelTempoEdit(); }
                e.stopPropagation();
            });
            inputEl.addEventListener('blur', () => this._commitTempoEdit());
        }

        // ── Touch expand/collapse ────────────────────────────────────────────
        //
        // On touch devices, tapping the lock dot or the HUD border (anything
        // that isn't an interactive control) toggles the expanded panel.
        // Tapping the circle still fires _tap() normally — the touch handler
        // only acts on "background" taps.
        //
        const hud = document.getElementById(HUD_ID);
        if (hud) {
            hud.addEventListener('touchend', (e) => {
                // Ignore taps that land on interactive controls
                const interactive = e.target.closest('button, input, span[id="ks-offset-val"]');
                if (interactive) return;
                e.preventDefault();
                this._hudExpanded ? this._closeHUD() : this._openHUD();
            }, { passive: false });

            // Lock dot click also toggles on desktop as a secondary affordance
            document.getElementById('ks-lock')
                ?.addEventListener('click', () => {
                    this._hudExpanded ? this._closeHUD() : this._openHUD();
                });
        }
    },
    _bindSeekBtns() {
        this.el.querySelectorAll('[data-verse-id] button[data-verse-id]').forEach(btn => {
            const fresh = btn.cloneNode(true);
            btn.replaceWith(fresh);
            fresh.addEventListener('click', () => {
                this._stopTimer();
                this._focusById(fresh.dataset.verseId);
                this._renderHUD();
            });
        });
    },
    _bindWindowEvents() {
        this._onEmphasis = ({ detail: { verseId } }) => this._focusById(verseId);
        this._onReset    = () => {
            this._stopTimer();
            this._verses().forEach(w => { w.dataset.stage = 'umbra'; });
            this._active  = null;
            this._period  = 0;
            this._lastTap = null;
            this._renderHUD();
        };
        window.addEventListener('phx:verseEmphasis',      this._onEmphasis);
        window.addEventListener('phx:verseEmphasisReset', this._onReset);
    },
    _bindKeyboard() {
        this._onKey = (e) => {
            if (['INPUT', 'TEXTAREA'].includes(e.target.tagName)) return;
            switch (e.key) {
            case ' ':
                e.preventDefault();
                if (this._running)     { this._pauseTimer(); }
                else if (this._paused) { this._resumeTimer(); }
                else                   { this._tap(); }
                break;
            case 'ArrowRight': case 'ArrowDown': case 'j':
                e.preventDefault(); this._tap(); break;
            case 'ArrowLeft': case 'ArrowUp': case 'k':
                e.preventDefault(); this._stopTimer(); this._retreat(); this._renderHUD(); break;
            case 'Escape':
                this._stopTimer(); this._renderHUD(); break;
            case 'r': case 'R':
                e.preventDefault(); this._hardReset(); break;
            case '-': this._nudgeOffset(-OFFSET_STEP); break;
            case '=': case '+': this._nudgeOffset(+OFFSET_STEP); break;
            case '0': this._resetOffset(); break;
            }
        };
        document.addEventListener('keydown', this._onKey);
    },
};

export default BhajStage;
