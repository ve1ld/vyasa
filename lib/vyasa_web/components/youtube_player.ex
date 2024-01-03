defmodule VyasaWeb.YouTubePlayer do
    use Phoenix.LiveComponent

    def render(assigns) do
      ~H"""
      <div>
        <div> ------- YOUTUBE PLAYER: ----- </div>
        <div
          crossorigin="anonymous"
          id="player"
          phx-hook="YouTubePlayer"
        />
      </div>
      """
    end


    def _render(assigns) do
      ~H"""
      <div>
        <div> ------- YOUTUBE PLAYER: ----- </div>
        <div
          crossorigin="anonymous"
          id="player"
        />
        <script
        id="youtubeScript"
        phx-hook="YouTubePlayer"
        >
        </script>


      <script>

          console.log(">>> mounted YouTubePlayer JS-Hook!!")
        // 2. This code loads the IFrame Player API code asynchronously.
        let tag = document.createElement("script");
        // tag.crossOrigin = 'anonymous'; /// seems like this will prevent the CORS allow origin from youtube to work correctly since it does the opposite (by allowing origin-only) REF: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/crossorigin
        tag.src = "https://www.youtube.com/iframe_api";
        let firstScriptTag = document.getElementsByTagName("script")[0];
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

        // 3. This function creates an <iframe> (and YouTube player)
        //    after the API code downloads.
        let player;
        function onYouTubeIframeAPIReady() {
        console.log(">>> iframe api ready")
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

        // 4. The API will call this function when the video player is ready.
        function onPlayerReady(event) {
        console.log(">>> player ready")
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

      </script>


      </div>
      """
    end
 end
