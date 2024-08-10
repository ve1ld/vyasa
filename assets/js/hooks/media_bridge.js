/**
 * Media Event Bus
 * Hooks for Media Bridge.
 * This hook shall interact with the display elements that give visual info about the generic
 * playback state, as well as emit events necessary to its children (i.e. the concrete players.).
 *
 * Event-handling is done using custom bridged events as a proxy.
 * */
import { formatDisplayTime } from "../utils/time_utils.js";
import {
  seekTimeBridge,
  playPauseBridge,
  heartbeatBridge,
  playbackMetaBridge,
} from "./mediaEventBridges";

MediaBridge = {
  mounted() {
    this.currentTime = this.el.querySelector("#player-time");
    this.isFollowMode = false;
    this.duration = this.el.querySelector("#player-duration");
    this.progress = this.el.querySelector("#player-progress");
    this.emphasizedDomNode = this.initEmphasizedNode();
    this.el.addEventListener("update_display_value", (e) =>
      this.handleUpdateDisplayValue(e),
    );
    this.handleEvent("media_bridge:registerEventsTimeline", (params) =>
      this.registerEventsTimeline(params),
    );
    this.handleEvent("media_bridge:registerPlayback", (params) =>
      this.registerPlaybackInfo(params),
    );
    this.handleEvent("initSession", (sess) => this.initSession(sess));
    // pub: external action
    // this callback pubs to others
    this.handleEvent("media_bridge:play_pause", (payload) =>
      this.receivePlayPauseFromServer(payload),
    );
    this.handleEvent("media_bridge:seekTime", (payload) =>
      this.receiveSeekTimeFromServer(payload),
    );
    this.handleEvent("toggleFollowMode", () => this.toggleFollowMode()); // TODO: candidate for shifting to media_bridge.js?
    // this callback: is internal to media_bridge
    // internal action
    this.eventBridgeDeregisterers = {
      seekTime: seekTimeBridge.sub((payload) => this.handleSeekTime(payload)),
      playPause: playPauseBridge.sub((payload) =>
        this.handlePlayPause(payload),
      ),
      heartbeat: heartbeatBridge.sub((payload) =>
        this.handleHeartbeat(payload),
      ),
    };
  },
  /**
   * Saves current session id
   * */
  initSession(sess) {
    localStorage.setItem("session", JSON.stringify(sess));
  },
  toggleFollowMode() {
    this.isFollowMode = !this.isFollowMode;
  },
  handleHeartbeat(payload) {
    const shouldIgnoreSignal = payload.originator === "MediaBridge";
    if (shouldIgnoreSignal) {
      return;
    }

    // originator is expected to be audio player
    console.assert(
      payload.originator === "AudioPlayer",
      "MediaBridge only expects heartbeat acks to come from AudioPlayer",
    );
    const { currentTimeMs, durationMs } = payload.currentPlaybackInfo || {};

    this.updateTimeDisplay(currentTimeMs, durationMs);
    this.emphasizeActiveEvent(currentTimeMs, this.eventsTimeline);
  },
  /**
   * Returns the map that gets used to init the preamble as the emphasized node.
   * This happens when the hook mounts.
   * */
  initEmphasizedNode() {
    const emphasizedChapterPreamble = this.emphasizeChapterPreamble();
    return {
      prev: null,
      current: emphasizedChapterPreamble,
    };
  },
  /**
   * Emphasizes then returns the node reference to the chapter's preamble.
   * This is so that @ mount, at least the chapter preamble shall be emphasized
   * */
  emphasizeChapterPreamble() {
    const preambleNode = document.querySelector("#chapter-preamble");
    if (!preambleNode) {
      console.warning("[EMPHASIZE], no preamble node found");
      return null;
    }

    preambleNode.classList.add("emphasized-verse");

    return preambleNode;
  },
  emphasizeActiveEvent(currentTimeMs, events) {
    if (!events) {
      return;
    }

    const activeEvent = events.find(
      (event) =>
        currentTimeMs >= event.origin &&
        currentTimeMs < event.origin + event.duration,
    );

    if (!activeEvent) {
      return;
    }

    const { verse_id: verseId } = activeEvent;

    if (!verseId) {
      return;
    }

    const { prev: prevDomNode, current: currDomNode } = this.emphasizedDomNode; // @ this point it wouldn't have been updated yet

    const updatedEmphasizedDomNode = {};
    if (currDomNode) {
      currDomNode.classList.remove("emphasized-verse");
      updatedEmphasizedDomNode.prev = currDomNode;
    }
    const targetDomId = `verse-${verseId}`;
    const targetNode = document.getElementById(targetDomId);
    targetNode.classList.add("emphasized-verse");
    updatedEmphasizedDomNode.current = targetNode;

    if (this.isFollowMode) {
      targetNode.focus();
      targetNode.scrollIntoView({
        behavior: "smooth",
        block: "start",
      });
    }

    this.emphasizedDomNode = updatedEmphasizedDomNode;
  },
  startHeartbeat() {
    const heartbeatInterval = 100; // 10fps, comfortable for human eye
    const heartbeatPayload = {
      originator: "MediaBridge",
    };
    const heartbeatTimer = setInterval(
      () => heartbeatBridge.pub(heartbeatPayload),
      heartbeatInterval,
    );
    this.heartbeatTimer = heartbeatTimer;
  },
  killHeartbeat() {
    clearInterval(this.heartbeatTimer);
  },
  updateTimeDisplay(timeMs, durationMs = null) {
    const currentTimeDisplay = formatDisplayTime(timeMs);
    this.currentTime.innerText = currentTimeDisplay;

    if (durationMs) {
      const durationDisplay = formatDisplayTime(durationMs);
      this.duration.innerText = durationDisplay;
    }
  },
  seekToMs(originator, timeMs) {
    const knownOriginators = ["ProgressBar", "MediaBridge"]; // temp-list, will be removed
    if (!knownOriginators.includes(originator)) {
      console.warn(
        `originator ${originator} is not a known originator. Is not one of ${knownOriginators}.`,
      );
    }
    this.updateTimeDisplay(timeMs);
  },
  handleUpdateDisplayValue(e) {
    const { detail } = e;
    const [key, val, extraKey] = detail?.payload;
    if (extraKey === "innerText") {
      this[key][extraKey] = val;
    }

    if (extraKey === "style.width") {
      this[key].style.width = val;
    }
  },
  registerEventsTimeline(params) {
    const { voice_events } = params;
    this.eventsTimeline = voice_events;
  },
  /**
   * First registers the playback information about a playable medium (e.g. voice).
   * The intent of this is to separate out tasks for interfacing with things like MediaSessions api
   * from interfacing with the concrete players (e.g. play pause event on the audio player).
   * */
  registerPlaybackInfo(params) {
    const { playback } = params;
    playbackMetaBridge.pub(playback);
  },
  /**
   * Receives event pushed from the server, then pubs through the
   * */
  receivePlayPauseFromServer(playPausePayload) {
    const { originator } = playPausePayload;
    console.assert(
      originator === "MediaBridge",
      "This event may only originate from the MediaBridge server.",
    );

    this.updateHeartbeatFromPlayPause(playPausePayload);
    playPauseBridge.pub(playPausePayload);
  },
  handlePlayPause(payload) {
    const { originator } = payload;

    const shouldIgnoreSignal = originator === "MediaBridge";
    if (shouldIgnoreSignal) {
      return;
    }

    this.updateHeartbeatFromPlayPause(payload);
  },
  /**
   * Updates the MediaBridgeHook's internal heartbeat timer depending on the command
   * given (play or pause).
   *
   * NOTE: This doesn't guard for the originator of the command.
   * */
  updateHeartbeatFromPlayPause(payload) {
    const { cmd } = payload;
    if (cmd === "play") {
      this.startHeartbeat();
    }
    if (cmd === "pause") {
      this.killHeartbeat();
    }
  },
  receiveSeekTimeFromServer(seekTimePayload) {
    const { originator } = seekTimePayload;
    console.assert(
      originator === "MediaBridge",
      "This event may only originate from the MediaBridge server.",
    );
    seekTimeBridge.pub(seekTimePayload);
  },
  handleSeekTime(payload) {
    const { seekToMs: timeMs, originator } = payload;
    this.seekToMs(originator, timeMs);
  },
};

export default MediaBridge;
