/**
 * Hooks for Media player.
 * This hook shall interact with the display elements that give visual info about the generic
 * playback state, as well as emit events necessary to its children (i.e. the concrete players.)
 * */

let nowSeconds = () => Math.round(Date.now() / 1000)
let rand = (min, max) => Math.floor(Math.random() * (max - min) + min)
let isVisible = (el) => !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length > 0)

let execJS = (selector, attr) => {
  document.querySelectorAll(selector).forEach(el => liveSocket.execJS(el, el.getAttribute(attr)))
}

MediaPlayer = {
  mounted() {
    this.currentTime = this.el.querySelector("#player-time")
    this.duration = this.el.querySelector("#player-duration")
    this.progress = this.el.querySelector("#player-progress")

    this.handleEvent("update_display_value", ([key, val, extraKey]) => {
      if (extraKey === "innerText") {
        this[key][extraKey] = val;
      }

      if (extraKey === "style.width") {
        this[key].style.width = val
      }
    })
}
}

export default MediaPlayer;
