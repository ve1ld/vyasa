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
export const seekTimeBridge = bridged('seekTime');

MediaBridge = {
  mounted() {
    this.currentTime = this.el.querySelector("#player-time")
    this.duration = this.el.querySelector("#player-duration")
    this.progress = this.el.querySelector("#player-progress")

    this.el.addEventListener("update_display_value", e => this.handleUpdateDisplayValue(e))

    // pub: external action
    // this callback pubs to others
    this.handleEvent("media_bridge:seekTime", (seekTimePayload) => {
      const {
        originator,
      } = seekTimePayload;
      console.assert(originator === "MediaBridge", "This event may only originate from the MediaBridge server.")
      console.log("found me? media_bridge:seekTime", seekTimePayload)
      seekTimeBridge.pub(seekTimePayload)

    })

    // this callback: is internal to media_bridge
    // internal action
    const seekTimeDeregisterer = seekTimeBridge.sub(payload => {
    console.log("[media_bridge::seekTimeBridgeSub::seekTimeHandler] this:", this);
      const {
        seekToMs: timeMs,
        originator,
      } = payload;
      const timeS = Math.round(timeMs/1000);
      this.seekToS(originator, timeS)
    })
  },
  updateTimeDisplay(timeS) {
    const beginTime = nowSeconds() - timeS
    const currentTimeDisplay = formatDisplayTime(timeS);
    this.currentTime.innerText = currentTimeDisplay
    console.log("Updated time display to", currentTimeDisplay);
  },
  seekToS(originator, timeS) {
    console.log("media_bridge.js::seekToS", {timeS, originator})
    const knownOriginators = ["ProgressBar"] // temp-list, will be removed
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
  }
}

export default MediaBridge;
