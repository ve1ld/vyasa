/**
 * Externalised hooks object to be used by app.js.
 */
import { getSharer } from "./web_share.js";


ShareQuoteButton = {
  mounted() {
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
    } else if ("clipboard" in navigator) {
      callback = () => {
        const verse = JSON.parse(this.el.getAttribute("data-verse"));
        navigator.clipboard.writeText(verse.text);
      };
    }

    this.el.addEventListener("click", callback);
  },
};

export default ShareQuoteButton;
