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
let rand = (min, max) => Math.floor(Math.random() * (max - min) + min)
let isVisible = (el) => !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length > 0)

let execJS = (selector, attr) => {
  document.querySelectorAll(selector).forEach(el => liveSocket.execJS(el, el.getAttribute(attr)))
}

import {seekTimeBridge, playPauseBridge, heartbeatBridge} from "./media_bridge.js"
import {formatDisplayTime, nowMs} from "../utils/time_utils.js"

AudioPlayer = {
  mounted() {
    this.isFollowMode = false;
    this.playbackBeganAt = null
    this.player = this.el.querySelector("audio")

    document.addEventListener("click", () => this.enableAudio())

    this.player.addEventListener("loadedmetadata", e => this.handleMetadataLoad(e))

    this.handleEvent("initSession", (sess) => this.initSession(sess))

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
      playback,
    } = payload

    if (cmd === "play") {
      this.playMedia(playback)
    }
    if (cmd === "pause") {
      this.pause()
    }
  },
  handleExternalSeekTime(payload) {
    console.log("[audio_player::seekTimeBridgeSub::seekTimeHandler] payload:", payload);
    const {seekToMs: timeMs} = payload;
    this.seekToMs(timeMs)
  },
  /**
   * Returns information about the current playback.
   *
   * NOTE: time-related values shall be in ms, even though media related read information
   * is documented to be in s.
   * */
  readCurrentPlaybackInfo() {
    const currentTimeMs = this.player.currentTime * 1000
    const durationMs = this.player.duration * 1000

    return {
        isPlaying: !this.player.paused,
        currentTimeMs,
        durationMs,
      }
  },
  echoHeartbeat(heartbeatPayload) {
    const shouldIgnoreSignal = heartbeatPayload.originator === "AudioPlayer";
    if(shouldIgnoreSignal) {
      return
    }

    console.log("[heartbeatBridge::audio_player] payload:", heartbeatPayload)
    const echoPayload = {
      originator: "AudioPlayer",
      currentPlaybackInfo: this.readCurrentPlaybackInfo()
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
  playMedia(playback) {
    console.log("PlayMedia", playback)
    const {meta: playbackMeta, "playing?": isPlaying, elapsed} = playback;
    const { title, duration, file_path: filePath, artists } = playbackMeta;
    const artist = artists ? artists.join(", ") : "Unknown artist";

    const beginTime = nowMs() - elapsed
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
    // TODO: supply necessary info for media sessions api here...
    this.updateMediaSession(playback)
  },
  play(opts = {}){
    console.log("Triggered playback, check params", {
      player: this.player,
      opts,
    })

    let {sync} = opts

    this.player.play().then(() => {
      if(sync) {
        const currentTimeMs = nowMs() - this.playbackBeganAt;

        this.player.currentTime = currentTimeMs / 1000;
        const formattedCurrentTime = formatDisplayTime(currentTimeMs);
      }
    }, error => {
      if(error.name === "NotAllowedError"){
        execJS("#enable-audio", "data-js-show")
      }
    })
  },
  // TODO: add triggers for updateMediaSession()
  pause(){
    this.player.pause()
  },
  stop(){
    this.player.pause()
    this.player.currentTime = 0
  },
  /**
   * The exposed api for html5 audio player is such that currentTime is a number value
   * in seconds.
   *
   * Hence, we shall convert the argument (in ms) to s, but without rounding off because a double float is accepted.
   * This preserves as much precision as possible.
   * */
  seekToMs(timeMs) {
    const beginTime = nowMs() - timeMs
    this.playbackBeganAt = beginTime;
    this.player.currentTime = timeMs / 1000;

    if (!this.player.paused) {
      this.player.play() // force a play event if is not paused
    }
  },
  updateMediaSession(playback) {
    const isSupported = "mediaSession" in navigator;
    if (!isSupported) {
      return;
    }
    const payload = this.createMediaMetadataPayload(playback)
    console.log("new metadata payload", payload)
    // navigator.mediaSession.metadata = new MediaMetadata(payload)

    navigator.mediaSession.metadata = new MediaMetadata({
      "title": "Hanuman Chalisa",
      "album": "Shree Hanuman Chalisa - Hanuman Ashtak",
      "artwork": [
        {
          "type": "image/jpeg",
          "src": "https://i.ytimg.com/vi/AETFvQonfV8/hqdefault.jpg",
          "sizes": "480x360"
        }
      ],
      "artist": "Hariharan, Gulshan Kumar",
      "extraKey": "foo"
    });

    // TODO: register action handlers
  },
  createMediaMetadataPayload(playback) {
    const {meta} = playback
    const session = navigator.mediaSession
    const sessionMetadata = session?.metadata
    const oldMetadata = sessionMetadata
          ? {
            title: sessionMetadata.title,
            artist: sessionMetadata.artist,
            album: sessionMetadata.album,
            artwork: sessionMetadata.artwork,
          }
          : {}

    const artist = meta?.artists
          ? meta.artists.join(", ")
          : sessionMetadata.artist ?? "Unknown artist";
    const metadata = {
      ...oldMetadata,
      ...meta,
      artist,
    }

    // const res = new MediaMetadata(metadata)
    console.log("creating new MediaMetadata", {
      oldMetadata,
      meta,
      sessionMetadata,
      metadata,
      // res
    })

    // return res
    return metadata
  }
}


export default AudioPlayer;
