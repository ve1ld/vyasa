/**
 * Hooks for audio player.
 * */

let nowSeconds = () => Math.round(Date.now() / 1000)
let rand = (min, max) => Math.floor(Math.random() * (max - min) + min)
let isVisible = (el) => !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length > 0)

let execJS = (selector, attr) => {
  document.querySelectorAll(selector).forEach(el => liveSocket.execJS(el, el.getAttribute(attr)))
}



AudioPlayer = {
  mounted() {
    this.playbackBeganAt = null
    this.player = this.el.querySelector("audio")
    this.currentTime = this.el.querySelector("#player-time")
    this.duration = this.el.querySelector("#player-duration")
    this.progress = this.el.querySelector("#player-progress")

    let enableAudio = () => {
      if(this.player.src){
        document.removeEventListener("click", enableAudio)
        const hasNothingToPlay = this.player.readyState === 0;
        if(hasNothingToPlay){
          this.player.play().catch(error => null)
          this.player.pause()
        }
      }
    }

    document.addEventListener("click", enableAudio)

    this.player.addEventListener("loadedmetadata", e => {
      console.log("Loaded metadata!", {
        duration: this.player.duration,
        event: e,
      })
    })

    this.el.addEventListener("js:listen_now", () => this.play({sync: true}))
    this.el.addEventListener("js:play_pause", () => {
      console.log("{play_pause event triggerred} player:", this.player)
      // toggle play-pause
      if(this.player.paused){
        this.play()
      }
    })

    this.handleEvent("initSession", (sess) => {
      localStorage.setItem("session", JSON.stringify(sess))
    })

    this.handleEvent("registerEventsTimeline", params => {
      console.log("Register Events Timeline", params);
      this.player.eventsTimeline = params.voice_events;
    })


    /// events handled by audio player::
    this.handleEvent("play", (params) => {
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
    })
    this.handleEvent("pause", () => this.pause())
    this.handleEvent("stop", () => this.stop())
    this.handleEvent("seekTo", params => this.seekTo(params))
  },
  clearNextTimer(){
    clearTimeout(this.nextTimer)
    this.nextTimer = null
  },
  clearProgressTimer() {
    console.log("[clearProgressTimer]", {
      timer: this.progressTimer,
    })
    clearInterval(this.progressTimer)
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
        this.player.currentTime = nowSeconds() - this.playbackBeganAt
      }
      const progressUpdateInterval = 100 // 10fps, comfortable for human eye

      if (!this.progressTimer) { // single instance of progress timer
        this.progressTimer = setInterval(() => this.updateProgress(), progressUpdateInterval)
      }
      console.log("[play: ProgressTimer]: ", this.progressTimer)

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
    this.clearProgressTimer()
    this.player.pause()
    this.player.currentTime = 0
    this.updateProgress()
    this.duration.innerText = ""
    this.currentTime.innerText = ""
  },
  seekTo(params) {
    const {
      positionS
    } = params;

    const beginTime = nowSeconds() - positionS
    this.playbackBeganAt = beginTime;
    this.currentTime = positionS;
    this.player.currentTime = positionS;
    this.updateProgress()
  },
  /**
   * Updates playback progress information.
   * */
  updateProgress() {
    // console.log("[updateProgress]", {
    //   eventsTimeline: this.player.eventsTimeline
    // })


    this.emphasizeActiveEvent(this.player.currentTime, this.player.eventsTimeline)


    if(isNaN(this.player.duration)) {
      console.log("player duration is nan")
      return false
    }

    const shouldStopUpdating = this.player.currentTime > 0 && this.player.paused
    if (shouldStopUpdating) {
      // console.log("Should stop updating")
      this.clearProgressTimer()
    }

    const shouldAutoPlayNextSong = !this.nextTimer && this.player.currentTime >= this.player.duration;
    if(shouldAutoPlayNextSong) {
      this.clearProgressTimer() // stops progress update
      const autoPlayMaxDelay = 1500
      this.nextTimer = setTimeout(
        // pushes next autoplay song to server:
        () => this.pushEvent("next_song_auto"),
        rand(0, autoPlayMaxDelay)
      )
      return
    }
    this.progress.style.width = `${(this.player.currentTime / (this.player.duration) * 100)}%`
    const durationVal = this.formatTime(this.player.duration);
    const currentTimeVal = this.formatTime(this.player.currentTime);
    console.log("update progress:", {
      player: this.player,
      durationVal,
      currentTimeVal,
    })
    this.duration.innerText = durationVal;
    this.currentTime.innerText = currentTimeVal;
    // this.pushEvent("update_playback_progress", {
    //   currentTimeVal,
    // })
    // this.pushEventTo("#chapter-index-container", "update_playback_progress", {
    //   currentTimeVal,
    // })
  },

  formatTime(seconds) {
    return new Date(1000 * seconds).toISOString().substring(11, 19)
  },
  emphasizeActiveEvent(currentTime, events) {

    if (!events) {
      console.log("No active events found")
      return;
    }

    const currentTimeMs = currentTime * 1000
    const activeEvent = events.find(event => currentTimeMs >= event.origin && currentTimeMs < (event.origin + event.duration))
    console.log("activeEvent:", {currentTimeMs, activeEvent})

    const {
      verse_id: verseId
    } = activeEvent;

    if (!verseId) {
      return
    }


    const classVals = ["bg-orange-500", "border-l-8", "border-black"]

    // TODO: this is a pedestrian approach that can be improved significantly:
    for (const otherDomNode of document.querySelectorAll('[id*="verse-"]')) {
      classVals.forEach(classVal => otherDomNode.classList.remove(classVal))
      otherDomNode.classList.remove("bg-orange-500")
    }

    const targetDomId = `verse-${verseId}`
    const node = document.getElementById(targetDomId)
    classVals.forEach(classVal => node.classList.add(classVal))
  }
}


export default AudioPlayer;
