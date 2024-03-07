/**
 * Hooks for audio player.
 * Leader
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
// TODO: shift to utils
let nowSeconds = () => Math.round(Date.now() / 1000)
let rand = (min, max) => Math.floor(Math.random() * (max - min) + min)
let isVisible = (el) => !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length > 0)

let execJS = (selector, attr) => {
  document.querySelectorAll(selector).forEach(el => liveSocket.execJS(el, el.getAttribute(attr)))
}

import {seekTimeBridge, playPauseBridge, heartbeatBridge} from "./media_bridge.js"
import {formatDisplayTime} from "../utils/time_utils.js"

AudioPlayer = {
  mounted() {
    this.isFollowMode = false;
    this.playbackBeganAt = null
    this.player = this.el.querySelector("audio")

    document.addEventListener("click", () => this.enableAudio())

    this.player.addEventListener("loadedmetadata", e => this.handleMetadataLoad(e))

    this.handleEvent("initSession", (sess) => this.initSession(sess)) // TODO: candidate for shifting to media_bridge.js?
    // this.handleEvent("registerEventsTimeline", params => this.registerEventsTimeline(params)) // TODO: candidate for shifting to media_bridge.js?
    // this.handleEvent("toggleFollowMode", () => this.toggleFollowMode()) // TODO: candidate for shifting to media_bridge.js?

    /// Audio playback events:
    this.handleEvent("stop", () => this.stop())

    /// maps eventName to its deregisterer:
    this.eventBridgeDeregisterers = {
      seekTime: seekTimeBridge.sub(payload => this.handleExternalSeekTime(payload)),
      playPause: playPauseBridge.sub(payload => this.handleMediaPlayPause(payload)),
      heartbeat: heartbeatBridge.sub(payload => this.echoHeartbeat(payload)),
    }
  },
  /// Handlers:
  handleMediaPlayPause(payload) {
    console.log("[playPauseBridge::audio_player::playpause] payload:", payload)
    const {
      cmd,
      player_details: playerDetails,
    } = payload

    if (cmd === "play") {
      this.playMedia(playerDetails)
    }
    if (cmd === "pause") {
      this.pause()
    }
  },
  handleExternalSeekTime(payload) {
    console.log("[audio_player::seekTimeBridgeSub::seekTimeHandler] this:", this);
    const {seekToMs: timeMs} = payload;
    const timeS = Math.round(timeMs/1000);
    this.seekToS(timeS)
  },
  echoHeartbeat(heartbeatPayload) {
    const shouldIgnoreSignal = heartbeatPayload.originator === "AudioPlayer";
    if(shouldIgnoreSignal) {
      return
    }

    console.log("[heartbeatBridge::audio_player] payload:", heartbeatPayload)
    const echoPayload = {
      originator: "AudioPlayer",
      currentPlaybackInfo: {
        isPlaying: !this.player.paused,
        currentTime: this.player.currentTime,
        duration: this.player.duration,
      }
    }
    heartbeatBridge.pub(echoPayload)
  },
  initSession(sess) {
    localStorage.setItem("session", JSON.stringify(sess))
  },
  handleMetadataLoad(e) {
    console.log("Loaded metadata!", {
      duration: this.player.duration,
      event: e,
    })
  },
  handlePlayPause() {
    console.log("{play_pause event triggerred} player:", this.player)
    if(this.player.paused){
      this.play()
    }
  },
  /**
   * This "init" behaviour has been mimicked from live_beats.
   * It is likely there to enable the audio player bufferring.
   * */
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
    console.log("PlayMedia", params)
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

    this.player.play().then(() => {
      if(sync) {
        const currentTime = nowSeconds() - this.playbackBeganAt
        this.player.currentTime = currentTime;
        const formattedCurrentTime = formatDisplayTime(currentTime);
      }
    }, error => {
      if(error.name === "NotAllowedError"){
        execJS("#enable-audio", "data-js-show")
      }
    })
  },
  pause(){
    // this.clearProgressTimer()
    this.player.pause()
  },
  stop(){
    this.player.pause()
    this.player.currentTime = 0
  },
  seekToS(time) {
    const beginTime = nowSeconds() - time
    this.playbackBeganAt = beginTime;
    this.player.currentTime = time;
  },
}


export default AudioPlayer;
