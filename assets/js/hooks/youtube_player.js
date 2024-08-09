/**
 * Follower
 * Validates if required parameters exist.
 * */
import { seekTimeBridge, playPauseBridge } from "./mediaEventBridges";

import { isMobileDevice } from "../utils/uncategorised_utils.js";

const isYouTubeFnCallable = (dataset) => {
  const { functionName, eventName } = dataset;
  const areFnAndEventNamesProvided = functionName && eventName;
  if (!areFnAndEventNamesProvided) {
    console.warn("Need to provide both valid function name and event name");
    return false;
  }
  const supportedEvents = ["click", "mouseover"];
  if (!supportedEvents.includes(eventName)) {
    console.warn(
      `${eventName} is not a supported event. Supported events include ${supportedEvents}.`,
    );
    return false;
  }
  const supportedFunctionNames = Object.keys(youtubePlayerCallbacks);
  if (!supportedFunctionNames.includes(functionName)) {
    console.warn(
      `${functionName} is not a supported youtube function. Supported functions include ${supportedFunctionNames}.`,
    );
    return false;
  }

  return true;
};

// NOTE: the player interface can be found @ https://developers.google.com/youtube/iframe_api_reference#Functions
const youtubePlayerCallbacks = {
  seekTo: function (options) {
    const { targetTimeStamp, player } = options;
    const target = Number(targetTimeStamp);
    console.log("seeking to: ", target);
    return player.seekTo(target);
  },
  loadVideoById: function (options) {
    const { targetTimeStamp: startSeconds, videoId, player } = options;
    console.log(`Loading video with id ${videoId} at t=${startSeconds}s`);
    player.loadVideoById({ videoId, startSeconds });
  },
  getAllStats: function (options) {
    // this is a custom function
    const { hook, player } = options;
    const stats = {
      duration: player.getDuration(),
      videoUrl: player.getVideoUrl(),
      currentTime: player.getCurrentTime(),
    };
    hook.pushEventTo("#statsHover", "reportVideoStatus", stats);
  },
};

/**
 * Contains client-side logic for the youtube iframe embeded player.
 * It shall contain multiple hooks, all revolving around various youtube player
 * functionalities that we wish to have.
 */
export const RenderYouTubePlayer = {
  mounted() {
    const { videoId, playerConfig: serialisedPlayerConfig } = this.el.dataset;
    console.log("Check dataset", this.el.dataset);

    const playerConfig = JSON.parse(serialisedPlayerConfig);
    const updatedConfig = overrideConfigForMobile(playerConfig);
    injectIframeDownloadScript();
    injectYoutubeInitialiserScript(videoId, updatedConfig);

    // TODO: capture youtube player events (play state changes and pub to the same event bridges, so as to control overall playback)
    this.eventBridgeDeregisterers = {
      seekTime: seekTimeBridge.sub((payload) => this.handleSeekTime(payload)),
      playPause: playPauseBridge.sub((payload) =>
        this.handlePlayPause(payload),
      ),
    };
    this.handleEvent("stop", () => this.stop());
  },
  handlePlayPause(payload) {
    console.log("[playPauseBridge::audio_player::playpause] payload:", payload);
    const { cmd, playback } = payload;

    if (cmd === "play") {
      this.playMedia(playback);
    }
    if (cmd === "pause") {
      this.pauseMedia();
    }
  },
  handleSeekTime(payload) {
    console.log(
      "[youtube_player::seekTimeBridgeSub::seekTimeHandler] check params:",
      { payload },
    );
    let { seekToMs: timeMs } = payload;
    this.seekToMs(timeMs);
  },
  playMedia(playback) {
    console.log("youtube player playMedia triggerred", playback);
    const { meta: playbackMeta, "playing?": isPlaying, elapsed } = playback;
    const { title, duration, file_path: filePath, artists } = playbackMeta;

    // TODO: consider if the elapsed ms should be used here for better sync(?)
    window.youtubePlayer.playVideo();
  },
  pauseMedia() {
    console.log("youtube player pauseMedia triggerred");
    window.youtubePlayer.pauseVideo();
  },
  stop() {
    console.log("youtube player stop triggerred");
  },
  seekToMs(timeMs) {
    const timeS = timeMs / 1000;
    console.log("youtube player seekto triggerred", {
      timeS,
      player: window.youtubePlayer,
    });

    window.youtubePlayer.seekTo(timeS);
  },
};

/**
 * Injects the script for the async download for the iframe as the first script
 * so that it gets fired before any other script.
 * */
const injectIframeDownloadScript = () => {
  const tag = document.createElement("script");
  tag.src = "https://www.youtube.com/iframe_api";
  const firstScriptTag = document.getElementsByTagName("script")?.[0];
  firstScriptTag && firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
};

/**
 * Injects a script that contains initialisation logic for the Youtube Player object.
 * */
const injectYoutubeInitialiserScript = (videoId, playerConfig) => {
  const iframeInitialiserScript = document.createElement("script");
  document.body.appendChild(iframeInitialiserScript);
  window.callbackYouTubeIframeAPIReady = () => {
    const assimilatedConfig = {
      ...playerConfig,
      videoId: videoId,
      events: {
        onReady: onPlayerReady,
      },
    };
    window.youtubePlayer = new YT.Player("player", assimilatedConfig);
  };
  window.callbackOnPlayerReady = (event) => {
    event.target.playVideo();
  };

  const stringifiedScript = `
    function onYouTubeIframeAPIReady() {
      window.callbackYouTubeIframeAPIReady();
    }
    function onPlayerReady(event) {
      window.callbackOnPlayerReady(event)
    }`;

  const functionCode = document.createTextNode(stringifiedScript);
  iframeInitialiserScript.appendChild(functionCode);
};

export const TriggerYouTubeFunction = {
  mounted() {
    if (!isYouTubeFnCallable(this.el.dataset)) {
      console.warn("YouTube function can not be triggerred.");
      return;
    }
    const { functionName, eventName } = this.el.dataset;
    const callback = youtubePlayerCallbacks[functionName];
    const getOptions = () => ({
      hook: this,
      ...this.el.dataset,
      player: window.youtubePlayer,
    });
    this.el.addEventListener(eventName, () => callback(getOptions()));
  },
};

/// FIXME: this is a temp fix, that overrides the dimensions if it's a mobile.
// there has to be a better, more generic way of handling this.
// Alternatively, if we can reverse engineer a custom PIP mode (with resize and all that), then
// we won't need to fix this.
const overrideConfigForMobile = (playerConfig) => {
  let overridedConfig = { ...playerConfig };
  if (isMobileDevice()) {
    (overridedConfig["height"] = "150"),
      (overridedConfig["width"] = "200"),
      console.log("[iframe] updating the player config:", {
        before: playerConfig,
        after: overridedConfig,
      });
  }

  return overridedConfig;
};
