SessionBox = {
  mounted() {
    this.handleEvent("initSession", (sess) => this.initSession(sess));

    this.handleEvent("session::share", (bind) => {
      if ("share" in navigator) {
      // uses webshare api:
        window.shareUrl(bind.url);
      } else if ("clipboard" in navigator) {
        navigator.clipboard.writeText(bind.url);
      } else {
        alert("Here is the url to share: #{bind.url}");
      }

    });
  },

  initSession(sess) {
    localStorage.setItem("session", JSON.stringify(sess));
  },
};

export default SessionBox;
