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

import { autoUpdate} from "floating-ui.dom.umd.min";

const autoUpdatePosition = () => {
  const {
    verseContainer,
    youtubePlayerContainer,
  } = getRelevantElements();


  autoUpdate(
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

import {
    computePosition,
    autoPlacement,
    shift,
    offset,
  } from "floating-ui.dom.umd.min";

const alignMiniPlayer = () => {
  const {verseContainer, youtubePlayerContainer} = getRelevantElements();


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
    Object.assign(youtubePlayerContainer.style, {
      left: `${x}px`,
      top: `${y}px`,
    });
  });

}

export default MiniPlayer;
