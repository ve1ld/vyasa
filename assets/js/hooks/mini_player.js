/**
 * Hooks to handle video miniplayer.
 * */

MiniPlayer = {
  mounted() {
    initMiniPlayer();
  }
}

const initMiniPlayer = () => {
  const {
    button,
  } = getRelevantElements();

  // registers some event listeners to these elements:
  [
    ["touchstart", toggleMiniPlayer],
    ["click", toggleMiniPlayer],
  ].forEach(([event, listener]) => {
    button.addEventListener(event, listener)
  })

  // first alignment!
  alignMiniPlayer()
}

const autoUpdatePosition = () => {
  const {
    verseContainer,
    youtubePlayerContainer,
  } = getRelevantElements();

  const {
    autoUpdate
  } = window.FloatingUIDOM

  window.FloatingUIDOM.cleanupAutoPositioning = autoUpdate(
    verseContainer,
    youtubePlayerContainer,
    alignMiniPlayer,
  )
}

const toggleMiniPlayer = () => {
  const {
    youtubePlayerContainer,
  } = getRelevantElements();
  const shouldShow = !youtubePlayerContainer.style.display

  youtubePlayerContainer.style.display = shouldShow ? "block" : "";
  // youtubePlayerContainer.style.background = isHidden ? "green" : "red";
  shouldShow && autoUpdatePosition();
  !shouldShow && alignMiniPlayer();
}

const getRelevantElements = () => {
  const id = "YouTubePlayer"
  const button = document.getElementById(`button-${id}`)
  const youtubePlayerContainer = document.getElementById(`container-${id}`)
  const verseContainer = document.getElementById("verseContainer")

  return {button, youtubePlayerContainer, verseContainer}
}

const alignMiniPlayer = () => {
  const {verseContainer, youtubePlayerContainer} = getRelevantElements();

  console.log("!! align mini player to verse container", {
    verseContainer,
    youtubePlayerContainer
  })
  const {
    computePosition,
    autoPlacement,
    shift,
    offset,
  } = window.FloatingUIDOM;


  computePosition(verseContainer, youtubePlayerContainer, {
    placement: 'right',
    // NOTE: order of middleware matters.
    middleware: [
      autoPlacement({
        allowedPlacements: [
          "right",
          "bottom"
        ]
      }),
      shift({
        padding: 32,
        crossAxis: true,
      }),
      offset(6),
    ],
  }).then(({x, y}) => {
    console.log(">>> computed new position for the player!", {
      x,
      y
    })
    Object.assign(youtubePlayerContainer.style, {
      left: `${x}px`,
      top: `${y}px`,
    });
  });

}

export default MiniPlayer;
