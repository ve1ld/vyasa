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
import {
  seekTimeBridge,
  playPauseBridge,
  heartbeatBridge,
  playbackMetaBridge,
} from "./mediaEventBridges";

let rand = (min, max) => Math.floor(Math.random() * (max - min) + min);
let isVisible = (el) =>
  !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length > 0);

let execJS = (selector, attr) => {
  document
    .querySelectorAll(selector)
    .forEach((el) => liveSocket.execJS(el, el.getAttribute(attr)));
};

import { formatDisplayTime, nowMs } from "../utils/time_utils.js";

AudioPlayer = {
  mounted() {
    this.isFollowMode = false;
    this.playbackBeganAt = null;
    this.player = this.el.querySelector("audio");
    console.log("MOUNT PING");

    // TO DEPRECATED
    // document.addEventListener("pointerdown", () => this.enableAudio());

    this.player.addEventListener("canplaythrough", (e) =>
      this.handlePlayableState(e),
    );
    // this.player.addEventListener("loadedmetadata", (e) =>
    //   this.handleMetadataLoad(e),
    // );
    /// Audio playback events:
    this.handleEvent("stop", () => this.stop());

    /// maps eventName to its deregisterer:
    this.eventBridgeDeregisterers = {
      seekTime: seekTimeBridge.sub((payload) =>
        this.handleExternalSeekTime(payload),
      ),
      playPause: playPauseBridge.sub((payload) =>
        this.handleMediaPlayPause(payload),
      ),
      heartbeat: heartbeatBridge.sub((payload) => this.echoHeartbeat(payload)),
      playbackMeta: playbackMetaBridge.sub((playback) =>
        this.handlePlaybackMetaUpdate(playback),
      ),
    };
  },
  /**
   * Loads the audio onto the audio player and inits the MediaSession as soon as playback information is received.
   * This allows the metadata and audio load to happen independently of users'
   * actions that effect playback (e.g. play/pause) -- bufferring gets init a lot earlier
   * as a result.
   * */
  handlePlaybackMetaUpdate(playback) {
    console.log("TRACE: handle playback meta update:", playback);
    const { meta: playbackMeta } = playback;
    const { file_path: filePath } = playbackMeta;
    this.loadAudio(filePath);
    this.initMediaSession(playback);
  },
  /// Handlers for events received via the events bridge:
  handleMediaPlayPause(payload) {
    console.log(
      "TRACE [playPauseBridge::audio_player::playpause] payload:",
      payload,
    );
    console.log("[playPauseBridge::audio_player::playpause] payload:", payload);
    const { cmd, playback } = payload;

    if (cmd === "play") {
      this.playMedia(playback);
    }
    if (cmd === "pause") {
      this.pause();
    }
  },
  handleExternalSeekTime(payload) {
    console.log(
      "[audio_player::seekTimeBridgeSub::seekTimeHandler] payload:",
      payload,
    );
    const { seekToMs: timeMs } = payload;
    this.seekToMs(timeMs);
  },
  /**
   * Returns information about the current playback.
   *
   * NOTE: time-related values shall be in ms, even though media related read information
   * is documented to be in s.
   * */
  readCurrentPlaybackInfo() {
    const currentTimeMs = this.player.currentTime * 1000;
    const durationMs = this.player.duration * 1000;

    return {
      isPlaying: !this.player.paused,
      currentTimeMs,
      durationMs,
    };
  },
  echoHeartbeat(heartbeatPayload) {
    const shouldIgnoreSignal = heartbeatPayload.originator === "AudioPlayer";
    if (shouldIgnoreSignal) {
      return;
    }

    console.log("[heartbeatBridge::audio_player] payload:", heartbeatPayload);
    const echoPayload = {
      originator: "AudioPlayer",
      currentPlaybackInfo: this.readCurrentPlaybackInfo(),
    };
    heartbeatBridge.pub(echoPayload);
  },
  handlePlayableState(e) {
    console.log("TRACE HandlePlayableState", e);
    // this.initMediaSession(playback);
  },
  // DEPRECATED: the state setting already happens at the point of loading, we don't need to listen to any metadata load event now now.
  handleMetadataLoad(e) {
    console.log("TRACE HandleMetadataLoad", e);
    // this.initMediaSession(playback);
  },
  handlePlayPause() {
    console.log("{play_pause event triggerred} player:", this.player);
    if (this.player.paused) {
      this.play();
    }
  },

  /*
   * This "init" behaviour has been mimicked from live_beats.
   * It is likely there to enable the audio player bufferring.
   */
  // DEPRECATED: the intent of this function is no longer clear. It can be removed in a cleanup commit coming soon.
  // the actual loading of audio to the audio player is already handled by loadAudio()
  enableAudio() {
    console.log("TRACE: enable audio");
    if (this.player.src) {
      console.log("TRACE: enable audio -- has a source", {
        src: this.player.src,
      });
      // we wait until the player is ready for this to be enabled, thereafter, we don't need to enable the player
      document.removeEventListener("pointerdown", this.enableAudio);
      const hasNothingToPlay = this.player.readyState === 0;
      if (hasNothingToPlay) {
        this.player.play().catch((error) => null);
        this.player.pause();
      }
    }
  },
  playMedia(playback) {
    console.log("PlayMedia", playback);

    const { meta: playbackMeta, "playing?": isPlaying, elapsed } = playback;
    const { title, duration, file_path: filePath, artists } = playbackMeta;
    const artist = artists ? artists.join(", ") : "Unknown artist";

    // TODO: supply necessary info for media sessions api here...
    this.updateMediaSession(playback);

    const beginTime = nowMs() - elapsed;
    this.playbackBeganAt = beginTime;
    console.log("TRACE @playMedia", {
      player: this.player,
    });
    let currentSrc = this.getCurrentSrc();
    const isLoadedAndPaused =
      currentSrc === filePath && !isPlaying && this.player.paused;
    if (isLoadedAndPaused) {
      this.play({ sync: true });
    } else if (currentSrc !== filePath) {
      this.loadAudio(filePath);
      this.play({ sync: true });
    }
  },
  loadAudio(src) {
    const isSrcAlreadyLoaded = src === this.getCurrentSrc();
    if (isSrcAlreadyLoaded) {
      return;
    }
    this.player.src = src;
  },
  getCurrentSrc() {
    if (!this?.player?.src) {
      return null;
    }
    // since the html5 player's src value is typically a url string, it will have url encodings e.g. ContentType.
    // Therefore, we strip away these urlencodes:
    const src = this.player.src.split("?")[0];

    return src;
  },
  play(opts = {}) {
    console.log("TRACE Triggered playback, check params", {
      player: this.player,
      opts,
    });

    let { sync } = opts;

    this.player.play().then(
      () => {
        if (sync) {
          const currentTimeMs = nowMs() - this.playbackBeganAt;

          this.player.currentTime = currentTimeMs / 1000;
          const formattedCurrentTime = formatDisplayTime(currentTimeMs);
        }
      },
      (error) => {
        if (error.name === "NotAllowedError") {
          execJS("#enable-audio", "data-js-show");
        }
      },
    );
  },
  // TODO: add triggers for updateMediaSession()
  pause() {
    this.player.pause();
  },
  stop() {
    this.player.pause();
    this.player.currentTime = 0;
  },
  /**
   * The exposed api for html5 audio player is such that currentTime is a number value
   * in seconds.
   *
   * Hence, we shall convert the argument (in ms) to s, but without rounding off because a double float is accepted.
   * This preserves as much precision as possible.
   * */
  seekToMs(timeMs) {
    const beginTime = nowMs() - timeMs;
    this.playbackBeganAt = beginTime;
    this.player.currentTime = timeMs / 1000;

    if (!this.player.paused) {
      this.player.play(); // force a play event if is not paused
    }
  },
  /**
   * At the point of init, we register some action handlers and update the media session's metadata
   * */
  initMediaSession(playback) {
    // TODO: register action handlers
    this.registerActionHandlers(playback);
    this.updateMediaSession(playback);
  },
  registerActionHandlers(playback) {
    const isSupported = "mediaSession" in navigator;
    if (!isSupported) {
      return;
    }

    const session = navigator.mediaSession;
    const playPauseEvents = ["play", "pause"];
    playPauseEvents.forEach((e) =>
      session.setActionHandler(e, (e) => this.dispatchPlayPauseToServer(e)),
    );
  },
  dispatchPlayPauseToServer(e) {
    console.log("TRACE Action handler invoked. Type: ", e);
    this.pushEvent("play_pause");
  },
  updateMediaSession(playback) {
    const isSupported = "mediaSession" in navigator;
    if (!isSupported) {
      return;
    }
    const payload = this.createMediaMetadataPayload(playback);
    console.log("new metadata payload", { playback, payload });
    navigator.mediaSession.metadata = new MediaMetadata(payload);
  },
  createMediaMetadataPayload(playback) {
    if (!playback) {
      return {};
    }
    const { meta } = playback;
    const sessionMetadata = navigator?.mediaSession?.metadata;
    const oldMetadata = sessionMetadata
      ? {
          title: sessionMetadata.title,
          artist: sessionMetadata.artist,
          album: sessionMetadata.album,
          artwork: sessionMetadata.artwork,
        }
      : {};

    const artist = meta?.artists
      ? meta.artists.join(", ")
      : (sessionMetadata.artist ?? "Unknown artist");
    const metadata = {
      ...oldMetadata,
      ...meta,
      artist,
    };

    return metadata;
  },
};

export default AudioPlayer;
