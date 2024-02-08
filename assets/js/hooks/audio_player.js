/**
 * Hooks for audio player.
 * */
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
      // toggle play-pause
      if(this.player.paused){
        this.play()
      }
    })


    /// events handled by audio player::
    this.handleEvent("play", (params) => {
      const {url, token, elapsed, artist, title} = params;
      console.log("play event, check params", params)
      this.playbackBeganAt = nowSeconds() - elapsed
      let currentSrc = this.player.src.split("?")[0]
      const isLoadedAndPaused = currentSrc === url && this.player.paused;
      if(isLoadedAndPaused){
        this.play({sync: true})
      } else if(currentSrc !== url) {
        // TODO: our case shall be simpler, our getter shall already display the token within the url
        currentSrc = `${url}?token=${token}`
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
      const progressUpdateInterval = 100
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
    this.duration.innerText = this.formatTime(this.player.duration)
    this.currentTime.innerText = this.formatTime(this.player.currentTime)
  },

  formatTime(seconds){ return new Date(1000 * seconds).toISOString().substring(14, 5) }
}


export default AudioPlayer;
