/**
 * Progress Bar hooks intended to sync playback related actions
 * */

import { seekTimeBridge, heartbeatBridge } from "./mediaEventBridges";

ProgressBar = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      e.preventDefault();
      this.handleProgressBarClick(e);
    });

    const heartbeatDeregisterer = heartbeatBridge.sub((payload) =>
      this.handleHeartbeat(payload),
    );
    const seekTimeDeregisterer = seekTimeBridge.sub((payload) =>
      this.handleExternalSeekTime(payload),
    );

    this.eventBridgeDeregisterers = {
      seekTime: seekTimeDeregisterer,
      heartbeat: heartbeatDeregisterer,
    };
  },
  handleExternalSeekTime(payload) {
    const { seekToMs: timeMs, originator } = payload;

    const shouldIgnoreSignal = originator === "ProgressBar";
    if (shouldIgnoreSignal) {
      return;
    }

    const maxTime = this.el.dataset?.max || this.maxTime;
    if (!maxTime) {
      console.warn(
        "Max time not available in element's state or dataset, ignoring progress bar update.",
      );
      return;
    }

    const playbackPercentage = timeMs / maxTime;
    const progressStyleWidth = `${playbackPercentage * 100}%`;
    this.setProgressBarWidth(progressStyleWidth);
  },
  handleHeartbeat(payload) {
    const shouldIgnoreSignal = payload.originator === "MediaBridge";
    if (shouldIgnoreSignal) {
      return;
    }
    const { currentTimeMs, durationMs } = payload.currentPlaybackInfo || {};

    const playbackPercentage = currentTimeMs / durationMs;
    const progressStyleWidth = `${playbackPercentage * 100}%`;
    this.setProgressBarWidth(progressStyleWidth);
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
    const { max: maxTime } = this.el.dataset;

    if (!maxTime) {
      return;
    }

    const containerNode = document.getElementById("player-progress-container");
    const maxOffset = containerNode.offsetWidth;
    this.maxTime = maxTime;
    this.maxOffset = maxOffset;

    const currXOffset = e.offsetX;
    const maxPlaybackMs = Number(maxTime);
    const playbackPercentage = currXOffset / maxOffset;
    const positionMs = maxPlaybackMs * playbackPercentage;
    const progressStyleWidth = `${playbackPercentage * 100}%`;
    this.setProgressBarWidth(progressStyleWidth);

    // Optimistic update
    this.el.value = positionMs;

    // pubs & dispatches this position
    const seekTimePayload = {
      seekToMs: positionMs,
      originator: "ProgressBar",
    };
    seekTimeBridge.dispatch(this, seekTimePayload, "#media-player-container");
    return;
  },
  setProgressBarWidth(progressStyleWidth, selector = "#player-progress") {
    const progressBarNode = document.querySelector(selector);
    console.assert(
      !!progressBarNode,
      "progress bar node must always be present in the dom.",
    );
    progressBarNode.style.width = progressStyleWidth;
  },
};

export default ProgressBar;
