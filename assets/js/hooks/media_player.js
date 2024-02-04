/**
 * Client side logic for our generic media player, which shall
 * be audio-first.
 * */
AudioPlayer = {
  mounted(){
    console.log("Mounted Audio player")
    this.playbackBeganAt = null
    this.player = this.el.querySelector("audio")
    this.currentTime = this.el.querySelector("#player-time")
    this.duration = this.el.querySelector("#player-duration")
    this.progress = this.el.querySelector("#player-progress")
    let enableAudio = () => {
      if(this.player.src){
        document.removeEventListener("click", enableAudio)
        if(this.player.readyState === 0){
          this.player.play().catch(error => null)
          this.player.pause()
        }
      }
    }

    document.addEventListener("click", enableAudio)
    this.el.addEventListener("js:listen_now", () => this.play({sync: true}))
    this.el.addEventListener("js:play_pause", () => {
      console.log("js:play_pause triggered", {
        isPaused: this.player.paused,
      });
      if(this.player.paused){
        this.play()
      }
    })

    this.handleEvent("play", (params) => {
      const {url, token, elapsed, artist, title} = params;
      console.log("Play event triggerred", {params})
      this.playbackBeganAt = nowSeconds() - elapsed
      let currentSrc = this.player.src.split("?")[0]
      if(currentSrc === url && this.player.paused){
        this.play({sync: true})
      } else if(currentSrc !== url) {
        this.player.src = `${url}?token=${token}`
        this.play({sync: true})
      }

      if("mediaSession" in navigator){
        navigator.mediaSession.metadata = new MediaMetadata({artist, title})
      }
    })

    this.handleEvent("pause", (params) => {
      console.log("pause event handled")
      this.pause()
    })
    this.handleEvent("stop", () => this.stop())
  },

  clearNextTimer(){
    clearTimeout(this.nextTimer)
    this.nextTimer = null
  },

  play(opts = {}){
    console.log(">> player.play()", {
      player: this.player,

    })
    let {sync} = opts
    this.clearNextTimer()
    this.player.play().then(() => {
      if(sync){ this.player.currentTime = nowSeconds() - this.playbackBeganAt }
      this.progressTimer = setInterval(() => this.updateProgress(), 100)
    }, error => {
      if(error.name === "NotAllowedError"){
        execJS("#enable-audio", "data-js-show")
      }
    })
  },

  pause(){
    console.log(">> player.pause()")
    clearInterval(this.progressTimer)
    this.player.pause()
  },

  stop(){
    console.log(">> player.stop()")
    clearInterval(this.progressTimer)
    this.player.pause()
    this.player.currentTime = 0
    this.updateProgress()
    this.duration.innerText = ""
    this.currentTime.innerText = ""
  },

  updateProgress(){
    console.log(">> player.stop()")
    if(isNaN(this.player.duration)){ return false }
    const hasFinishedPlayingSong = !this.nextTimer && this.player.currentTime >= this.player.duration;
    if(hasFinishedPlayingSong){
      clearInterval(this.progressTimer)
      this.nextTimer = setTimeout(() => this.pushEvent("next_song_auto"), rand(0, 1500))
      return
    }
    this.progress.style.width = `${(this.player.currentTime / (this.player.duration) * 100)}%`
    this.duration.innerText = this.formatTime(this.player.duration)
    this.currentTime.innerText = this.formatTime(this.player.currentTime)
  },

  formatTime(seconds){ return new Date(1000 * seconds).toISOString().substring(14, 5) }
}


export default AudioPlayer;
