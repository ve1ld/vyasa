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
    } else if ("clipboard" in navigator) { // copies to clipboard:
      callback = () => {
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

export default ShareQuoteButton;
