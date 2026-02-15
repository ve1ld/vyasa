defmodule VyasaWeb.Context.Read.Tracks do
  use VyasaWeb, :live_component

  @impl true
  def update(params, socket) do
    send(self(), {"mutate_UiState", "hide_media_bridge", []})
    {:ok, socket |> assign(params)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="track-stage"
      phx-hook="BhajStage"
      class="min-h-screen overflow-x-hidden"
    >
      <div class="h-[30dvh]" aria-hidden="true"></div>

      <div id="karoke-stream" phx-update="stream">
        <div
          :for={{dom_id, track} <- @tracks}
          id={dom_id}
          data-stage="umbra"
          data-verse-id={track.event.verse.id}
          data-track-order={track.order}
          emph_verse_id={track.event.verse.id}
          class={[
            "group relative flex flex-col items-center px-6",
            "pb-2",
            "scroll-mt-[15dvh] scroll-mb-[25vh]",
            "transition-all duration-[600ms] ease-[cubic-bezier(0.4,0,0.2,1)]",

            # ── UMBRA ─────────────────────────────────────────────────────────
            # Near-invisible: spatial placeholder. Heavy blur kills periphery.
            "opacity-[0.6]",

            # ── PREV: receding ghost ──────────────────────────────────────────
            # Confirms passage. DELIBERATELY dim — the cliff is HERE, not above.
            # 0.70 opacity drop between prev(0.22) and upcoming(0.92).
            "data-[stage=prev]:opacity-[0.8]",

            # ── UPCOMING: penumbra — performer's safety net ───────────────────
            # 92% opacity: the follow-spot's warm edge. Readable NOW, not soon.
            # Only 8% dimmer than active — glow is the sole differentiator.
            # Zero blur. Nearly-active scale. Leans toward active (-translate-y).
            "data-[stage=upcoming]:opacity-[0.90]",
            "data-[stage=upcoming]:scale-[0.95]",
            "data-[stage=upcoming]:blur-none",

            # ── ACTIVE: centre-stage ──────────────────────────────────────────
            "data-[stage=active]:opacity-100",
            "data-[stage=active]:scale-100",
            "data-[stage=active]:translate-y-0",
            "data-[stage=active]:blur-none",
          ]}
          >

    <%!-- ─── OM SCENE BREAK ─────────────────────────────────────────────
            The breath between verses. Belongs optically to the verse above.
            Line width grows with intensity: umbra=0 → prev=tiny → upcoming=medium → active=wide.
            This creates a sense of "exhale" at active and "inhale" at upcoming.
          --%>
          <div
          :if={!is_nil(track.cluster_id)}
            aria-hidden="true"
            class="relative z-10 flex items-center justify-center w-full pt-6 pb-3 gap-[1rem]"
          >
            <div class={[
              "h-px bg-gradient-to-r from-transparent via-amber-800/50 to-transparent",
              "transition-all duration-[600ms]",
              "opacity-[0.06] w-10",
              "group-data-[stage=prev]:opacity-[0.12] group-data-[stage=prev]:w-14",
              "group-data-[stage=upcoming]:opacity-[0.38] group-data-[stage=upcoming]:w-24",
              "group-data-[stage=active]:opacity-[0.72] group-data-[stage=active]:w-36",
            ]}></div>

            <span class={[
              font_class(track.event.verse.source.lang),
              "text-[0.9rem] leading-none flex-shrink-0",
              "transition-all duration-[600ms]",
              "text-amber-900/15 opacity-15",
              "group-data-[stage=prev]:opacity-[0.18]",
              "group-data-[stage=upcoming]:text-[#D4850A]/60 group-data-[stage=upcoming]:opacity-65",
              "group-data-[stage=active]:text-[#ff9933] group-data-[stage=active]:opacity-100",
              "group-data-[stage=active]:[text-shadow:0_0_12px_rgba(255,153,51,0.65),0_0_32px_rgba(255,153,51,0.28)]",
            ]}>ௐ</span>

            <div class={[
              "h-px bg-gradient-to-l from-transparent via-amber-800/50 to-transparent",
              "transition-all duration-[600ms]",
              "opacity-[0.06] w-10",
              "group-data-[stage=prev]:opacity-[0.12] group-data-[stage=prev]:w-14",
              "group-data-[stage=upcoming]:opacity-[0.38] group-data-[stage=upcoming]:w-24",
              "group-data-[stage=active]:opacity-[0.72] group-data-[stage=active]:w-36",
            ]}></div>
          </div>

          <%!-- ─── BLOOM LAYER 1: active follow-spot — wide alabaster warmth ─ --%>
          <div
            aria-hidden="true"
            class={[
              "absolute pointer-events-none z-0",
              "inset-[-4rem_-8rem_-2rem_-8rem]",
              "transition-opacity duration-[600ms] opacity-0",
              "group-data-[stage=active]:opacity-100",
            ]}
          ></div>

          <%!-- ─── BLOOM LAYER 2: upcoming halo — coral-saffron anticipation ─ --%>
          <div
            aria-hidden="true"
            class={[
              "absolute pointer-events-none z-0",
              "inset-[-2rem_-5rem_-1rem_-5rem]",
              "transition-opacity duration-[600ms] opacity-0",
              "group-data-[stage=upcoming]:opacity-100",
            ]}
            style="background: radial-gradient(ellipse 58% 42% at 50% 48%,
                     rgba(255,153,51,0.08) 0%,
                     rgba(255,131,73,0.04) 45%,
                     transparent 75%)"
          ></div>

          <%!-- ─── BLOOM LAYER 3: active stage-floor — rust ground plane ─────── --%>
          <div
            aria-hidden="true"
            class={[
              "absolute pointer-events-none z-0",
              "inset-x-0 bottom-0 h-32",
              "transition-opacity duration-[600ms] opacity-0",
              "group-data-[stage=active]:opacity-100",
            ]}
            style="background: radial-gradient(ellipse 80% 100% at 50% 100%,
                     rgba(174,55,0,0.07) 0%,
                     transparent 70%)"
          ></div>

          <%!-- ═══════════════════ CONTENT LAYER ══════════════════════════════ --%>
          <div class="relative z-10 w-full max-w-[54rem] mx-auto flex flex-col items-center my-6">

            <%!-- ─── SOURCE ANNOTATION ────────────────────────────────────────
              Metadata orients without competing (Tufte).
              Upcoming: warm hint at peripheral readability.
              Active: coral-orange — confirms location, does not shout.
            --%>
            <div class="absolute flex justify-left w-full">
              <button
                class={[
                  "left px-3  rounded-full bg-transparent border-none cursor-pointer",
                  "transition-all duration-300 hover:bg-amber-800/10",
                  "opacity-30 pointer-events-none",
                  "group-data-[stage=upcoming]:opacity-100 group-data-[stage=upcoming]:pointer-events-auto",
                  "group-data-[stage=active]:opacity-100 group-data-[stage=active]:pointer-events-auto",
                ]}
                
                aria-label={"Seek to #{track.event.verse.chapter_no}·#{track.event.verse.no}"}
              >
                <span class={[
                  font_class(track.event.verse.source.lang),
                  "uppercase",
                  "transition-all duration-300",
                  # Upcoming: dim warm
                  "text-amber-700/50",
                  # Active: coral-saffron, slightly wider tracking
                  "group-data-[stage=active]:text-[#FF9933]",
                  "text-shadow:0_0_12px_rgba(255,153,51,0.65),0_0_32px_rgba(255,153,51,0.28)"
                ]}>
                  <%= track.event.verse.chapter.title%>
                  &thinsp;·&thinsp;
                  <%= track.event.verse.chapter_no %>.<%= track.event.verse.no %>
                </span>
              </button>
            </div>
            <p
              data-verse-id={track.event.verse.id}
              class={[
                font_class(track.event.verse.source.lang),
                "text-center  tracking-[0.03em] text-[clamp(1.52rem,3.75vw,3.0rem)]",
                "hyphens-none break-keep whitespace-pre-line",
                "m-0 transition-all duration-[600ms] ease-[cubic-bezier(0.4,0,0.2,1)]",
                "text-[#1a120a] ",
                
                "group-data-[stage=prev]:text-[#cdc4a4]",
                
                # Must be read instantly under time pressure. No blur. No compromise.
                "group-data-[stage=upcoming]:text-[#cdc4a4]",
                "group-data-[stage=active]:text-[#F3EFE3]",
    
                "group-data-[stage=active]:[text-shadow:0_0_28px_rgba(243,239,227,0.25),0_0_72px_rgba(243,239,227,0.09),0_0_160px_rgba(255,153,51,0.06)]",
              ]}
              verse_id={track.event.verse.id}
            >
              <%= track.event.verse.body %>
            </p>
          </div>

          

        </div><%!-- /verse row --%>
      </div><%!-- /karoke-stream --%>

      <div class="h-[65vh]" aria-hidden="true"></div>
    </div>
    """
  end

  defp font_class(lang), do: "font-#{lang}"
end
