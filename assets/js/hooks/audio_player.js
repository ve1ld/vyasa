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
    this.el.addEventListener("js:listen_now", () => this.play({sync: true}))
    this.el.addEventListener("js:play_pause", () => {
      console.log("{play_pause event triggerred} player:", this.player)
      // toggle play-pause
      if(this.player.paused){
        this.play()
      }
    })


    /// events handled by audio player::
    this.handleEvent("play", (params) => {
      const {filePath, url, elapsed, artist, title} = params;
      const beginTime = nowSeconds() - elapsed
      this.playbackBeganAt = beginTime
      console.log("play event, check params", {params, beginTime})
      let currentSrc = this.player.src.split("?")[0]
      const isLoadedAndPaused = currentSrc === filePath && this.player.paused;
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
    this.handleEvent("pause", () => {
      console.log(">> triggerred pause")
      this.pause()
    })
    this.handleEvent("stop", () => this.stop())
  },

  clearNextTimer(){
    clearTimeout(this.nextTimer)
    this.nextTimer = null
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
      const progressUpdateInterval = 50
      this.progressTimer = setInterval(() => this.updateProgress(), progressUpdateInterval)
    }, error => {
      if(error.name === "NotAllowedError"){
        execJS("#enable-audio", "data-js-show")
      }
    })
  },

  pause(){
    clearInterval(this.progressTimer)
    this.player.pause()
  },

  stop(){
    clearInterval(this.progressTimer)
    this.player.pause()
    this.player.currentTime = 0
    this.updateProgress()
    this.duration.innerText = ""
    this.currentTime.innerText = ""
  },

  /**
   * Updates playback progress information.
   * */
  updateProgress() {
    if(isNaN(this.player.duration)) {
      return false
    }
    const shouldAutoPlayNextSong = !this.nextTimer && this.player.currentTime >= this.player.duration;
    if(shouldAutoPlayNextSong) {
      clearInterval(this.progressTimer) // stops progress updates
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
  },

  formatTime(seconds) {
    return new Date(1000 * seconds).toISOString().substring(11, 19)
  }
}


export default AudioPlayer;
