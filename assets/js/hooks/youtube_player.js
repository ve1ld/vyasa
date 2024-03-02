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

/// NOTE: the player interface can be found @ https://developers.google.com/youtube/iframe_api_reference#Functions
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
