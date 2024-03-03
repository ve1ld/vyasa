/**
 * Hooks for audio player.
 * This hook shall interact with the html5 player via it's known apis, on things like:
 * 1. playback info relevant to the audio player
 *
 *
 * Additionally, it shall emit events back to it's corresponding parent hook (MediaPlayer)
 * so that the media player can effect changes to visual info like player timestamps, durations and such.
 *
 * In this way, "Playback" state is managed by MediaBridge, and is displayed by the Media Library hook to follow a
 * general player-agnostic fashion. "Playback" and actual playback (i.e. audio or video playback) is decoupled, allowing
 * us the ability to reconcile bufferring states and other edge cases, mediated by the Media Bridge.
 * */
let nowSeconds = () => Math.round(Date.now() / 1000)
let rand = (min, max) => Math.floor(Math.random() * (max - min) + min)
let isVisible = (el) => !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length > 0)

let execJS = (selector, attr) => {
  document.querySelectorAll(selector).forEach(el => liveSocket.execJS(el, el.getAttribute(attr)))
}

AudioPlayer = {
  mounted() {
    this.isFollowMode = false;
    this.playbackBeganAt = null
    this.player = this.el.querySelector("audio")
    this.emphasizedDomNode = {
      prev: null,
      current: null,
    }

    document.addEventListener("click", () => this.enableAudio())
    this.player.addEventListener("loadedmetadata", e => this.handleMetadataLoad(e))
    this.el.addEventListener("js:listen_now", () => this.play({sync: true}))
    this.el.addEventListener("js:play_pause", () => this.handlePlayPause())
    this.handleEvent("initSession", (sess) => this.initSession(sess))
    this.handleEvent("registerEventsTimeline", params => this.registerEventsTimeline(params))

    /// events handled by non-media player::
    this.handleEvent("toggleFollowMode", () => this.toggleFollowMode())

    /// events handled by media player::
    this.handleEvent("play_media", (params) => this.playMedia(params))
    this.handleEvent("pause_media", () => this.pause())
    this.handleEvent("stop", () => this.stop())
    this.handleEvent("seekTo", params => this.seekTo(params))

  },
  /// Handlers:
  toggleFollowMode() {
    this.isFollowMode = !this.isFollowMode
  },
  initSession(sess) {
    localStorage.setItem("session", JSON.stringify(sess))
  },
  clearNextTimer(){
    clearTimeout(this.nextTimer)
    this.nextTimer = null
  },
  clearProgressTimer() {
    this.updateProgress()
    console.log("[clearProgressTimer]", {
      timer: this.progressTimer,
    })
    clearInterval(this.progressTimer)
  },
  handleMetadataLoad(e) {
    console.log("Loaded metadata!", {
      duration: this.player.duration,
      event: e,
    })
  },
  registerEventsTimeline(params) {
    console.log("Register Events Timeline", params);
    this.player.eventsTimeline = params.voice_events;
  },
  handlePlayPause() {
    console.log("{play_pause event triggerred} player:", this.player)
    // toggle play-pause
    if(this.player.paused){
      this.play()
    }
  },
  enableAudio() {
    if(this.player.src){
      document.removeEventListener("click", this.enableAudio)
      const hasNothingToPlay = this.player.readyState === 0;
      if(hasNothingToPlay){
        this.player.play().catch(error => null)
        this.player.pause()
      }
    }
  },
  playMedia(params) {
    const {filePath, isPlaying, elapsed, artist, title} = params;
    const beginTime = nowSeconds() - elapsed
    this.playbackBeganAt = beginTime
    let currentSrc = this.player.src.split("?")[0]
    const isLoadedAndPaused = currentSrc === filePath && !isPlaying && this.player.paused;
    if(isLoadedAndPaused){
      this.play({sync: true})
    } else if(currentSrc !== filePath) {
      currentSrc = filePath
      this.player.src = currentSrc
      this.play({sync: true})
    }

    const isMediaSessionApiSupported = "mediaSession" in navigator;
    if(isMediaSessionApiSupported){
      navigator.mediaSession.metadata = new MediaMetadata({artist, title})
    }
  },
  play(opts = {}){
    console.log("Triggered playback, check params", {
      player: this.player,
      opts,
    })

    let {sync} = opts
    this.clearNextTimer()

    //
    this.player.play().then(() => {
      if(sync) {
        const currentTime = nowSeconds() - this.playbackBeganAt
        this.player.currentTime = currentTime;
        const formattedCurrentTime = this.formatTime(currentTime);
        this.emitMediaBridgeJSUpdate("currentTime", formattedCurrentTime)
      }
      this.syncProgressTimer()
    }, error => {
      if(error.name === "NotAllowedError"){
        execJS("#enable-audio", "data-js-show")
      }
    })
  },
  pause(){
    this.clearProgressTimer()
    this.player.pause()
  },
  stop(){
    this.player.pause()
    this.player.currentTime = 0
    this.clearProgressTimer()
    this.emitMediaBridgeJSUpdate("currentTime", "")
    this.emitMediaBridgeJSUpdate("duration", "")
  },
  seekTo(params) {
    const {
      positionS
    } = params;

    const beginTime = nowSeconds() - positionS
    this.playbackBeganAt = beginTime;
    const formattedBeginTime = this.formatTime(positionS);
    this.emitMediaBridgeJSUpdate("currentTime", formattedBeginTime)
    this.player.currentTime = positionS;
    this.syncProgressTimer()
  },

  /**
   * Calls the update progress fn at a set interval,
   * replaces an existing progress timer, if it exists.
   * */
  syncProgressTimer() {
    const progressUpdateInterval = 100 // 10fps, comfortable for human eye
    const hasExistingTimer = this.progressTimer
    if(hasExistingTimer) {
      this.clearProgressTimer()
    }
    if (this.player.paused) {
      return
    }
    this.progressTimer = setInterval(() => this.updateProgress(), progressUpdateInterval)
  },
  /**
   * Updates playback progress information.
   * */
  updateProgress() {
    this.emphasizeActiveEvent(this.player.currentTime, this.player.eventsTimeline)

    if(isNaN(this.player.duration)) {
      console.log("player duration is nan")
      return false
    }

    const shouldStopUpdating = this.player.currentTime > 0 && this.player.paused
    if (shouldStopUpdating) {
      this.clearProgressTimer()
    }

    const shouldAutoPlayNextSong = !this.nextTimer && this.player.currentTime >= this.player.duration;
    if(shouldAutoPlayNextSong) {
      this.clearProgressTimer() // stops progress update
      const autoPlayMaxDelay = 1500
      this.nextTimer = setTimeout(
        // pushes next autoplay song to server:
        // FIXME: this shall be added in in the following PRs
        () => this.pushEvent("next_song_auto"),
        rand(0, autoPlayMaxDelay)
      )
      return
    }
    const progressStyleWidth = `${(this.player.currentTime / (this.player.duration) * 100)}%`
    this.emitMediaBridgeJSUpdate("progress", progressStyleWidth, "style.width")
    const durationVal = this.formatTime(this.player.duration);
    const currentTimeVal = this.formatTime(this.player.currentTime);
    console.log("update progress:", {
      player: this.player,
      durationVal,
      currentTimeVal,
    })
    this.emitMediaBridgeJSUpdate("currentTime", currentTimeVal);
    this.emitMediaBridgeJSUpdate("duration", durationVal)
  },

  formatTime(seconds) {
    return new Date(1000 * seconds).toISOString().substring(11, 19)
  },
  emphasizeActiveEvent(currentTime, events) {
    if (!events) {
      console.log("No events found")
      return;
    }

    const currentTimeMs = currentTime * 1000
    const activeEvent = events.find(event => currentTimeMs >= event.origin &&
                                    currentTimeMs < (event.origin + event.duration))
    console.log("activeEvent:", {currentTimeMs, activeEvent})

    if (!activeEvent) {
      console.log("No active event found @ time = ", currentTime)
      return;
    }

    const {
      verse_id: verseId
    } = activeEvent;

    if (!verseId) {
      return
    }

    // TODO: convert to a pre-defined css class "emphasizedVerse"
    const classVals = ["emphasized-verse"]

    const {
      prev: prevDomNode,
      current: currDomNode,
    } = this.emphasizedDomNode; // @ this point it wouldn't have been updated yet

    // TODO: shift to media_bridge specific hook
    const updatedEmphasizedDomNode = {}
    if(currDomNode) {
      currDomNode.classList.remove("emphasized-verse")
      updatedEmphasizedDomNode.prev = currDomNode;
    }
    const targetDomId = `verse-${verseId}`
    const targetNode = document.getElementById(targetDomId)
    targetNode.classList.add("emphasized-verse")
    updatedEmphasizedDomNode.current = targetNode;

    if(this.isFollowMode) {
      targetNode.focus()
      targetNode.scrollIntoView({ behavior: 'smooth' });
    }

    this.emphasizedDomNode = updatedEmphasizedDomNode;
  },
  emitMediaBridgeJSUpdate(key, value, extraKey = "innerText") {
    const customEvent = new CustomEvent("update_display_value", {
      bubbles: true,
      detail: {payload: [key, value, extraKey]},
    });

    const targetElement = document.querySelector("#media-player-container");
    targetElement.dispatchEvent(customEvent)
  }
}


export default AudioPlayer;
