/**
 * Contains client-side logic for the youtube iframe embeded player.
 * It shall contain multiple hooks, all revolving around various youtube player
 * functionalities that we wish to have.
 */
export const RenderYouTubePlayer = {
  mounted() {
    console.log(">>> mounted YouTubePlayer JS-Hook!!", this);
    // 2. This code loads the IFrame Player API code asynchronously.
    let tag = document.createElement("script");
    const foo = document.getElementById("player");
    console.log("FOO before: ", foo);
    // tag.crossOrigin = 'anonymous'; /// seems like this will prevent the CORS allow origin from youtube to work correctly since it does the opposite (by allowing origin-only) REF: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/crossorigin
    tag.src = "https://www.youtube.com/iframe_api";
    console.log(">>> script tags:", document.getElementsByTagName("script"));
    /// ensures that the API script is loaded before any subsequent scripts that depend on it, hence we insert before the first script tag:
    let firstScriptTag = document.getElementsByTagName("script")[0];
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

    console.log(
      ">> after insertion, script tags:",
      document.getElementsByTagName("script"),
    );
    let iframeInitialiserScript = document.createElement("script");
    document.body.appendChild(iframeInitialiserScript);
    const stringifiedScript = `
    function onYouTubeIframeAPIReady() {
      console.log(">>> iframe api ready, time to create iframe...");
      window.youtubePlayer = new YT.Player("player", {
        height: "390",
        width: "640",
        videoId: "M7lc1UVf-VE",
        playerVars: {
          "playsinline": 1,
        },
        events: {
          "onReady": onPlayerReady,
          "onStateChange": onPlayerStateChange,
        },
      });
    }

    console.log(">>> window-attached youtube player: ", window.youtubePlayer);

    // 4. The API will call this function when the video player is ready.
    function onPlayerReady(event) {
      console.log(">>> player ready");
      event.target.playVideo();
    }

    // 5. The API calls this function when the player's state changes.
    //    The function indicates that when playing a video (state=1),
    //    the player should play for six seconds and then stop.
    let done = false;
    function onPlayerStateChange(event) {
      if (event.data == YT.PlayerState.PLAYING && !done) {
        setTimeout(myTimedCallback, 1000);
        done = true;
      }
    }
    function myTimedCallback() {
      console.log("triggerred myTimedCallback()")
      console.log(">> check player reference:", window.youtubePlayer)
    }
    `
    const functionCode = document.createTextNode(stringifiedScript);
    iframeInitialiserScript.appendChild(functionCode)
  },
};

export const TriggerYouTubeFunction = {
  mounted() {
    if (!isYouTubeFnCallable(this.el.dataset)) {
      console.warn("YouTube function can not be triggerred.")
      return
    }
    const {functionName, eventName} = this.el.dataset
    const callback = callbacks[functionName]
    const getOptions = () => ({hook: this,...this.el.dataset, player: window.youtubePlayer})
    this.el.addEventListener(eventName, () => callback(getOptions()))
  }
}

/// NOTE: the player interface can be found @ https://developers.google.com/youtube/iframe_api_reference#Functions
const callbacks = {
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
    console.log(">>> Retrieved stats:", stats)
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
  const supportedFunctionNames = Object.keys(callbacks)
  if (!supportedFunctionNames.includes(functionName)) {
    console.warn(`${functionName} is not a supported youtube function. Supported functions include ${supportedFunctionNames}.`);
    return false;
  }


  return true
}
