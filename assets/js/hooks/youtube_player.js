/**
 * Validates if required parameters exist.
 * */
const isYouTubeFnCallable = (dataset) => {
  const {functionName, eventName} = dataset;
  const areFnAndEventNamesProvided = functionName && eventName
  if(!areFnAndEventNamesProvided) {
    console.warn("Need to provide both valid function name and event name");
    return false
  }
  const supportedEvents = ["click", "mouseover"]
  if (!supportedEvents.includes(eventName)) {
    console.warn(`${eventName} is not a supported event. Supported events include ${supportedEvents}.`);
    return false
  }
  const supportedFunctionNames = Object.keys(youtubePlayerCallbacks)
  if (!supportedFunctionNames.includes(functionName)) {
    console.warn(`${functionName} is not a supported youtube function. Supported functions include ${supportedFunctionNames}.`);
    return false;
  }


  return true
}

// NOTE: the player interface can be found @ https://developers.google.com/youtube/iframe_api_reference#Functions
const youtubePlayerCallbacks = {
  seekTo: function(options) {
    const {targetTimeStamp, player} = options;
    const target = Number(targetTimeStamp)
    console.log("seeking to: ", target)
    return player.seekTo(target)
  },
  loadVideoById: function(options) {
    const {
      targetTimeStamp: startSeconds,
      videoId,
      player,
    } = options;
    console.log(`Loading video with id ${videoId} at t=${startSeconds}s`)
    player.loadVideoById({videoId, startSeconds})
  },
  getAllStats: function(options)  { // this is a custom function
    const {
      hook,
      player,
    } = options;
    const stats = {
      duration: player.getDuration(),
      videoUrl: player.getVideoUrl(),
      currentTime: player.getCurrentTime(),
    }
    hook.pushEventTo("#statsHover", "reportVideoStatus", stats)
  }
}

/**
 * Contains client-side logic for the youtube iframe embeded player.
 * It shall contain multiple hooks, all revolving around various youtube player
 * functionalities that we wish to have.
 */
export const RenderYouTubePlayer = {
  mounted() {
    const {
      videoId,
      playerConfig: serialisedPlayerConfig,
    } = this.el.dataset;
    console.log("Check dataset", this.el.dataset)

    const playerConfig = JSON.parse(serialisedPlayerConfig)
    injectIframeDownloadScript()
    injectYoutubeInitialiserScript(videoId, playerConfig)
    this.el.addEventListener("js:listen_now", () => this.play())
    this.el.addEventListener("js:play_pause", () => this.handlePlayPause())

    // events handled by media player:
    this.handleEvent("play_media", (params) => this.playMedia(params))
    this.handleEvent("pause_media", () => this.pause())
    this.handleEvent("stop", () => this.stop())
    this.handleEvent("seekTo", params => this.seekTo(params))
  },
  // TODO: wire up the event handlers completely
  handlePlayPause() {
    console.log("youtube player handlePlayPause triggerred")
    window.youtubePlayer.playVideo()
  },
  playMedia(params) {
    console.log("youtube player playMedia triggerred", params)
    window.youtubePlayer.playVideo()
  },
  play(params) {
    console.log("youtube player play triggerred", params)
  },
  pause() {
    console.log("youtube player pause_media triggerred")
    window.youtubePlayer.seekTo(100)
    window.youtubePlayer.pauseVideo()
  },

  stop() {
    console.log("youtube player stop triggerred")
  },
  seekTo(params) {
    console.log("youtube player seekto triggerred", {
      params,
      player: window.youtubePlayer
    })
    const {
      positionS: targetS,
    } = params

    window.youtubePlayer.seekTo(targetS)
  }
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
}

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
      }
    }
    window.youtubePlayer = new YT.Player("player", assimilatedConfig)
  }
  window.callbackOnPlayerReady = (event) => {
    event.target.playVideo();
  }

  const stringifiedScript = `
    function onYouTubeIframeAPIReady() {
      window.callbackYouTubeIframeAPIReady();
    }
    function onPlayerReady(event) {
      window.callbackOnPlayerReady(event)
    }`

  const functionCode = document.createTextNode(stringifiedScript);
  iframeInitialiserScript.appendChild(functionCode)
}

export const TriggerYouTubeFunction = {
  mounted() {
    if (!isYouTubeFnCallable(this.el.dataset)) {
      console.warn("YouTube function can not be triggerred.")
      return
    }
    const {functionName, eventName} = this.el.dataset
    const callback = youtubePlayerCallbacks[functionName]
    const getOptions = () => ({hook: this,...this.el.dataset, player: window.youtubePlayer})
    this.el.addEventListener(eventName, () => callback(getOptions()))
  }
}

