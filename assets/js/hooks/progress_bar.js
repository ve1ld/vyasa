/**
 * Progress Bar hooks intended to sync playback related actions
 *
 * */

import {seekTimeBridge} from "./media_bridge.js"

ProgressBar = {
  mounted() {
    this.el.addEventListener("click", (e) => {
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

      const containerNode = document.getElementById("player-progress-container")
      const maxPlaybackMs = Number(maxTime)
      const maxOffset = containerNode.offsetWidth
      const currXOffset = e.offsetX;
      const playbackPercentage = (currXOffset / maxOffset)
      const positionMs = maxPlaybackMs * playbackPercentage
      const progressStyleWidth = `${(playbackPercentage)}%`
      this.el.style.width = progressStyleWidth


      // Optimistic update
      this.el.value = positionMs;

      console.log("seek attempt @ positionMs:", {
        event: e,
        maxOffset,
        currXOffset,
        playbackPercentage,
        maxPlaybackMs,
        positionMs
      })

      // push event to bridge
      seekTimeBridge.dispatchTo(this, {seekToMs: positionMs}, "#media-player-container")
      //this.pushEventTo(, "seekToMs", {  });

      return;
    });
  }
};


export default ProgressBar;
