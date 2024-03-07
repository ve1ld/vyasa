/**
 * Media Event Bus
 * Hooks for Media Bridge.
 * This hook shall interact with the display elements that give visual info about the generic
 * playback state, as well as emit events necessary to its children (i.e. the concrete players.).
 *
 * Event-handling is done using custom bridged events as a proxy.
 * */
import { bridged } from "./media/bridged.js";
import { formatDisplayTime } from "../utils/time_utils.js"

let nowSeconds = () => Math.round(Date.now() / 1000)
let rand = (min, max) => Math.floor(Math.random() * (max - min) + min)
let isVisible = (el) => !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length > 0)

let execJS = (selector, attr) => {
  document.querySelectorAll(selector).forEach(el => liveSocket.execJS(el, el.getAttribute(attr)))
}

// TODO: consider switching to a map of bridges to support other key events
export const seekTimeBridge = bridged("seekTime");
export const playPauseBridge = bridged("playPause")
export const heartbeatBridge = bridged("heartbeat")

MediaBridge = {
  mounted() {
    this.currentTime = this.el.querySelector("#player-time")
    this.isFollowMode = false;
    this.duration = this.el.querySelector("#player-duration")
    this.progress = this.el.querySelector("#player-progress")

    const emphasizedChapterPreamble = this.emphasizeChapterPreamble()
    this.emphasizedDomNode = {
      prev: null,
      current: emphasizedChapterPreamble,
    }
    this.el.addEventListener("update_display_value", e => this.handleUpdateDisplayValue(e))
    this.handleEvent("media_bridge:registerEventsTimeline", params => this.registerEventsTimeline(params))

    // pub: external action
    // this callback pubs to others
    this.handleEvent("media_bridge:seekTime", (seekTimePayload) => {
      const {
        originator,
      } = seekTimePayload;
      console.assert(originator === "MediaBridge", "This event may only originate from the MediaBridge server.")

      seekTimeBridge.pub(seekTimePayload)
    })

    this.handleEvent("media_bridge:play_pause", (playPausePayload) => {
      const {
        originator,
      } = playPausePayload;
      console.assert(originator === "MediaBridge", "This event may only originate from the MediaBridge server.")

      console.log("media_bridge:play_pause", playPausePayload)
      playPauseBridge.pub(playPausePayload)
    })

    this.handleEvent("toggleFollowMode", () => this.toggleFollowMode()) // TODO: candidate for shifting to media_bridge.js?

    // this callback: is internal to media_bridge
    // internal action
    this.eventBridgeDeregisterers = {
      seekTime: seekTimeBridge.sub(payload => this.handleSeekTime(payload)),
      playPause: playPauseBridge.sub(payload => this.handlePlayPause(payload)),
      heartbeat: heartbeatBridge.sub(payload => this.handleHeartbeat(payload)),
    }
  },
  toggleFollowMode() {
    this.isFollowMode = !this.isFollowMode;
  },
  handleHeartbeat(payload) {
    console.log("[MediaBridge::handleHeartbeat]", payload)
    const shouldIgnoreSignal = payload.originator === "MediaBridge";
    if(shouldIgnoreSignal) {
      return;
    }

    // originator is expected to be audio player
    console.assert(payload.originator === "AudioPlayer", "MediaBridge only expects heartbeat acks to come from AudioPlayer");
    console.log(">>> progress update, payload:", {payload, eventsTimeline: this.eventsTimeline})
    const playbackInfo = payload.currentPlaybackInfo;
    const {
      currentTime: currentTimeS,
      duration: durationS,
    } = playbackInfo || {};

    this.updateTimeDisplay(currentTimeS, durationS)
    this.emphasizeActiveEvent(currentTimeS, this.eventsTimeline)
  },
  /**
   * Emphasizes then returns the node reference to the chapter's preamble.
   * This is so that @ mount, at least the chapter preamble shall be emphasized
   * */
  emphasizeChapterPreamble() {
    const preambleNode = document.querySelector("#chapter-preamble")
    if (!preambleNode) {
      console.log("[EMPHASIZE], no preamble node found")
      return null
    }

    preambleNode.classList.add("emphasized-verse")

    console.log("[EMPHASIZE], preamble node:", preambleNode)

    return preambleNode
  },
  emphasizeActiveEvent(currentTime, events) {
    if (!events) {
      console.log("No events found")
      return;
    }

    const currentTimeMs = currentTime * 1000
    const activeEvent = events.find(event => currentTimeMs >= event.origin &&
                                    currentTimeMs < (event.origin + event.duration))

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

    const {
      prev: prevDomNode,
      current: currDomNode,
    } = this.emphasizedDomNode; // @ this point it wouldn't have been updated yet

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
      targetNode.scrollIntoView({
        behavior: 'smooth',
        block: 'start',
      });
    }

    this.emphasizedDomNode = updatedEmphasizedDomNode;
  },
  startHeartbeat() {
    const heartbeatInterval = 100 // 10fps, comfortable for human eye
    console.log("Starting heartbeat!")
    const heartbeatPayload = {
      originator: "MediaBridge",
    }
    const heartbeatTimer = setInterval(() => heartbeatBridge.pub(heartbeatPayload), heartbeatInterval)
    console.log("Started Heartbeat with:", {heartbeatTimer, heartbeatPayload, heartbeatInterval})

    this.heartbeatTimer = heartbeatTimer
  },
  killHeartbeat() {
    console.log("Killing heartbeat!", {heartbeatTimer: this.heartbeatTimer})
    clearInterval(this.heartbeatTimer)
  },
  updateTimeDisplay(timeS, durationS=null) {
    const beginTime = nowSeconds() - timeS
    const currentTimeDisplay = formatDisplayTime(timeS);
    this.currentTime.innerText = currentTimeDisplay
    console.log("Updated time display to", currentTimeDisplay);

    if(durationS) {
      const durationDisplay = formatDisplayTime(durationS)
      this.duration.innerText = durationDisplay
    }
  },
  seekToS(originator, timeS) {
    console.log("media_bridge.js::seekToS", {timeS, originator})
    const knownOriginators = ["ProgressBar", "MediaBridge"] // temp-list, will be removed
    if (!knownOriginators.includes(originator)) {
      console.warn(`originator ${originator} is not a known originator. Is not one of ${knownOriginators}.`)
    }
    this.updateTimeDisplay(timeS);
  },
  handleUpdateDisplayValue(e) {
    const {
      detail,
    } = e
    const [key, val, extraKey] = detail?.payload
    if (extraKey === "innerText") {
      this[key][extraKey] = val;
    }

    if (extraKey === "style.width") {
      this[key].style.width = val
    }
  },
  registerEventsTimeline(params) {
    console.log("Register Events Timeline", params);
    this.eventsTimeline = params.voice_events
  },
  handleSeekTime(payload) {
    console.log("[media_bridge::seekTimeBridgeSub::seekTimeHandler] this:", this);
    const {
      seekToMs: timeMs,
      originator,
    } = payload;
    const timeS = Math.round(timeMs/1000);
    this.seekToS(originator, timeS)
  },
  handlePlayPause(payload) {
    console.log("[playPauseBridge::media_bridge:playpause] payload:", payload)
    const {
      cmd,
      player_details: playerDetails,
      originator,
    } = payload

    // TODO: implement handler for actions emitted via interaction with youtube player
    console.log(">> [media_bridge.js::playPauseBridge], received a signal", payload)
    if (cmd === "play") {
      this.startHeartbeat()
    }
    if (cmd === "pause") {
      this.killHeartbeat()
    }
  }

}

export default MediaBridge;
