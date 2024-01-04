/**
 * Contains client-side logic for the youtube iframe embeded player.
 */

YouTubePlayer = {
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
    let player;
    function onYouTubeIframeAPIReady() {
      console.log(">>> iframe api ready, time to create iframe...");
      player = new YT.Player("player", {
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

    console.log(">>> player: ", player);

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
        setTimeout(stopVideo, 6000);
        done = true;
      }
    }
    function stopVideo() {
      player.stopVideo();
    }
    `
    const functionCode = document.createTextNode(stringifiedScript);
    iframeInitialiserScript.appendChild(functionCode)
  },
};

export default YouTubePlayer;
