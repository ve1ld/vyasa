/**
 * Externalised hooks object to be used by app.js.
 */
import { getSharer } from "./web_share.js";


ShareQuoteButton = {
  mounted() {
    initTooltip();
    let callback = () => console.log("share quote!");

    if ("share" in navigator) { // uses webshare api:
      callback = () => {
        const shareTitle = this.el.getAttribute("data-share-title");
        const shareUrl = window.location.href;
        const sharer = getSharer("url", shareTitle, shareUrl);
        if (!sharer) {
          return;
        }

        window.shareUrl = sharer;
        window.shareUrl(shareUrl);
      };
    } else if ("clipboard" in navigator) { // copies to clipboard:
      callback = () => {
        console.log(">> see me:", {"floating ui:": window})
        const {
          chapter_number: chapterNum,
          verse_number: verseNum,
          transliteration,
          text,
        } = JSON.parse(this.el.getAttribute("data-verse"));

        const content = `[Gita Chapter ${chapterNum} Verse ${verseNum}] \n${text}\n${transliteration}\nRead more at ${document.URL}`
        navigator.clipboard.writeText(content);
      };
    }

    this.el.addEventListener("click", callback);
  },
};

function showTooltip() {
  const {tooltip} = getButtonAndTooltip();
  tooltip.style.display = 'block';
  alignTooltip();
}

function hideTooltip() {
  const {tooltip} = getButtonAndTooltip();
  tooltip.style.display = '';
}

const initTooltip = () => {
  const {button} = getButtonAndTooltip();

  [
    ['mouseenter', showTooltip],
    ['mouseleave', hideTooltip],
    ['focus', showTooltip],
    ['blur', hideTooltip],
  ].forEach(([event, listener]) => {
    button.addEventListener(event, listener);
  });
}

const getButtonAndTooltip = () => {
  const id = "ShareQuoteButton"
  const button = document.getElementById(id)
  const tooltip = document.getElementById(`tooltip-${id}`)
  return {button, tooltip}

}


const alignTooltip = () => {
  const {button, tooltip} = getButtonAndTooltip()
  console.log(">>> found?", {
    button,
    tooltip,
  })
  const {
    computePosition,
    flip,
    shift,
    offset,
  } = window.FloatingUIDOM;
  computePosition(button, tooltip, {
    placement: 'right',
    // NOTE: order of middleware matters.
    middleware: [offset(6), flip(), shift({padding: 16})],
  }).then(({x, y}) => {
    console.log(">>> computed new position!", {
      x,
      y
    })
    Object.assign(tooltip.style, {
      left: `${x}px`,
      top: `${y}px`,
    });
  });
}


export default ShareQuoteButton;
