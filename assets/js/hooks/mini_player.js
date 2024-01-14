/**
 * Hooks to handle video miniplayer.
 * */

MiniPlayer = {
  mounted() {
    initMiniPlayer();
  }
}

/**
 * Initialises a miniplayer by binding the relevant listener to
 * the events that trigger (and aligns) this miniplayer on the relevant dom element.
 * */
const initMiniPlayer = () => {
  const {
    button,
  } = getRelevantElements();

  const events = ["touchstart", "click"]
  const listeners = [toggleMiniPlayer]
  bindListenersToEventsOnEl(button, listeners, events)

  alignMiniPlayer()
}

/**
 * Given a dom element and a list of events and listeners,
 * binds all the listeners to each event for that element.
 * */
const bindListenersToEventsOnEl = (el, listeners, events) => {
  events.forEach(event => {
    listeners.forEach(listener => el.addEventListener(event, listener))
  });
};

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
  youtubePlayerContainer.classList.toggle("container-YouTubePlayerHidden")
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
