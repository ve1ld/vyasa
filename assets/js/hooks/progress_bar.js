/**
 * Progress Bar hooks intended to sync playback related actions
 * */

import {seekTimeBridge, heartbeatBridge} from "./media_bridge.js"

ProgressBar = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      e.preventDefault();
      this.handleProgressBarClick(e)
    });

    const heartbeatDeregisterer = heartbeatBridge.sub(payload => this.handleHeartbeat(payload))
    const seekTimeDeregisterer = seekTimeBridge.sub(payload => this.handleExternalSeekTime(payload))

    this.eventBridgeDeregisterers = {
      seekTime: seekTimeDeregisterer,
      heartbeat: heartbeatDeregisterer,
    }
  },
  handleExternalSeekTime(payload) {
    console.log("[progress_bar::seekTimeBridgeSub::seekTimeHandler] this:", {payload});
    const {
      seekToMs: timeMs,
      originator,
    } = payload;

    const shouldIgnoreSignal = originator === "ProgressBar";
    if (shouldIgnoreSignal) {
      console.info("Ignoring signal for seekTime", payload)

      return;
    }

    const maxTime = this.el.dataset?.max || this.maxTime
    if(!maxTime) {
      console.warn("Max time not available in element's state or dataset, ignoring progress bar update.")
      return
    }

    const playbackPercentage = (timeMs / maxTime)
    const progressStyleWidth = `${(playbackPercentage * 100)}%`
    console.log("[DEBUG]", {
      maxTime,
      playbackPercentage,
    })
    this.setProgressBarWidth(progressStyleWidth)
  },
  handleHeartbeat(payload) {
    console.log("[ProgressBar::handleHeartbeat]", payload)
    const shouldIgnoreSignal = payload.originator === "MediaBridge";
    if(shouldIgnoreSignal) {
      return;
    }
    const {
      currentTimeMs,
      durationMs,
    } = payload.currentPlaybackInfo || {};

    const playbackPercentage = (currentTimeMs / durationMs)
    const progressStyleWidth = `${(playbackPercentage * 100)}%`
    console.log("handleHeartbeat, set progress bar width", progressStyleWidth)
    this.setProgressBarWidth(progressStyleWidth)
  },
  /*
    // The progress bar is measured in milliseconds,
    // with `min` set at 0 and `max` at the duration of the track.
    //
    // [--------------------------X-----------]
    // 0                          |       offsetWidth
    //                            |
    // [--------------------------] e.target.offsetX
    //
    // When the user clicks on the progress bar (represented by X), we get
    // the position of the click in pixels (e.target.offsetX).
    //
    // We know that we can express the relationship between pixels
    // and milliseconds as:
    //
    // e.target.offsetX : e.target.offsetWidth = X : max
    //
    // To find X, we do:
    // console.log("check possible positions info:", {
    //   e.
    // })
   */
  handleProgressBarClick(e) {
    const { max: maxTime } = this.el.dataset

    if (!maxTime) {
      console.log("unable to seek position, payload is incorrect")
      return
    }

    const containerNode = document.getElementById("player-progress-container")
    const maxOffset = containerNode.offsetWidth
    this.maxTime = maxTime;
    this.maxOffset = maxOffset;

    const currXOffset = e.offsetX;
    const maxPlaybackMs = Number(maxTime)
    const playbackPercentage = (currXOffset / maxOffset)
    const positionMs = maxPlaybackMs * playbackPercentage
    const progressStyleWidth = `${(playbackPercentage * 100)}%`
    this.setProgressBarWidth(progressStyleWidth)

    // Optimistic update
    this.el.value = positionMs;

    console.log("seek attempt @ positionMs:", {
      checkThis: this,
      elem: this.el,
      event: e,
      maxOffset,
      currXOffset,
      playbackPercentage,
      maxPlaybackMs,
      positionMs,
    })

    // pubs & dispatches this position
    const seekTimePayload = {
      seekToMs: positionMs,
      originator: "ProgressBar",
    }
    seekTimeBridge.dispatch(this, seekTimePayload, "#media-player-container")
    return;
  },
  setProgressBarWidth(progressStyleWidth, selector="#player-progress") {
    console.log("setting progress bar width:", progressStyleWidth)
    const progressBarNode = document.querySelector(selector)
    console.assert(!!progressBarNode, "progress bar node must always be present in the dom.")
    progressBarNode.style.width = progressStyleWidth;
  }
};


export default ProgressBar;
