/**
 * Media Event Bus
 * Hooks for Media Bridge.
 * This hook shall interact with the display elements that give visual info about the generic
 * playback state, as well as emit events necessary to its children (i.e. the concrete players.).
 *
 * Event-handling is done using custom bridged events as a proxy.
 * */
import { bridged } from "./media/bridged.js";
import { formatDisplayTime } from "../utils/time_utils.js";

// TODO: consider switching to a map of bridges to support other key events
export const seekTimeBridge = bridged("seekTime");
export const playPauseBridge = bridged("playPause");
export const heartbeatBridge = bridged("heartbeat");

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
  toggleFollowMode() {
    this.isFollowMode = !this.isFollowMode;
  },
  handleHeartbeat(payload) {
    console.log("[MediaBridge::handleHeartbeat]", payload);
    const shouldIgnoreSignal = payload.originator === "MediaBridge";
    if (shouldIgnoreSignal) {
      return;
    }

    // originator is expected to be audio player
    console.assert(
      payload.originator === "AudioPlayer",
      "MediaBridge only expects heartbeat acks to come from AudioPlayer",
    );
    console.log(">>> progress update, payload:", {
      payload,
      eventsTimeline: this.eventsTimeline,
    });
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
      console.log("No events found");
      return;
    }

    const activeEvent = events.find(
      (event) =>
        currentTimeMs >= event.origin &&
        currentTimeMs < event.origin + event.duration,
    );

    if (!activeEvent) {
      console.log("No active event found @ time = ", currentTime);
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
    console.log("Starting heartbeat!");
    const heartbeatPayload = {
      originator: "MediaBridge",
    };
    const heartbeatTimer = setInterval(
      () => heartbeatBridge.pub(heartbeatPayload),
      heartbeatInterval,
    );
    console.log("Started Heartbeat with:", {
      heartbeatTimer,
      heartbeatPayload,
      heartbeatInterval,
    });

    this.heartbeatTimer = heartbeatTimer;
  },
  killHeartbeat() {
    console.log("Killing heartbeat!", { heartbeatTimer: this.heartbeatTimer });
    clearInterval(this.heartbeatTimer);
  },
  updateTimeDisplay(timeMs, durationMs = null) {
    const currentTimeDisplay = formatDisplayTime(timeMs);
    this.currentTime.innerText = currentTimeDisplay;
    console.log("Updated time display to", currentTimeDisplay);

    if (durationMs) {
      const durationDisplay = formatDisplayTime(durationMs);
      this.duration.innerText = durationDisplay;
    }
  },
  seekToMs(originator, timeMs) {
    console.log("media_bridge.js::seekToMs", { timeMs, originator });
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
    console.log("Register Events Timeline", params);
    this.eventsTimeline = params.voice_events;
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

    console.log("media_bridge:play_pause", playPausePayload);
    playPauseBridge.pub(playPausePayload);
  },
  handlePlayPause(payload) {
    console.log("[playPauseBridge::media_bridge:playpause] payload:", payload);
    const { cmd, playback, originator } = payload;

    // TODO: implement handler for actions emitted via interaction with youtube player
    console.log(
      ">> [media_bridge.js::playPauseBridge], received a signal",
      payload,
    );
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
    console.log("media_bridge:seekTime event handler", seekTimePayload);
    seekTimeBridge.pub(seekTimePayload);
  },
  handleSeekTime(payload) {
    console.log(
      "[media_bridge::seekTimeBridgeSub::seekTimeHandler] payload",
      payload,
    );
    const { seekToMs: timeMs, originator } = payload;
    this.seekToMs(originator, timeMs);
  },
};

export default MediaBridge;
