/**
 * Progress Bar hooks intended to sync playback related actions
 *
 * */

import {seekTimeBridge} from "./media_bridge.js"

ProgressBar = {
  mounted() {
    this.el.addEventListener("click", (e) => this.handleProgressBarClick(e));
  },
  handleProgressBarClick(e) {
    // The progress bar is measure in milliseconds,
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

    const {
      max: maxTime,
    } = this.el.dataset

    if (!maxTime) {
      console.log("unable to seek position, payload is incorrect")
      return
    }

    // TODO: extract calculation logic to separate fn
    const maxPlaybackMs = Number(maxTime)
    const containerNode = document.getElementById("player-progress-container")
    const maxOffset = containerNode.offsetWidth
    const currXOffset = e.offsetX;
    const playbackPercentage = (currXOffset / maxOffset)
    const positionMs = maxPlaybackMs * playbackPercentage
    const progressStyleWidth = `${(playbackPercentage * 100)}%`
    console.log("updating progress bar to width = ", {
      containerNode,
      maxPlaybackMs,
      maxOffset,
      currXOffset,
      playbackPercentage,
      progressStyleWidth,
      positionMs,
    })

    const progressBarNode = document.querySelector("#player-progress")
    console.assert(!!progressBarNode, "progress bar node must always be present in the dom.")
    progressBarNode.style.width = progressStyleWidth;

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
      progressBarNode,
    })

    // pubs & dispatches this position
    const seekTimePayload = {
      seekToMs: positionMs,
      originator: "ProgressBar",
    }
    seekTimeBridge.dispatch(this, seekTimePayload, "#media-player-container")
    return;
  },
};


export default ProgressBar;
