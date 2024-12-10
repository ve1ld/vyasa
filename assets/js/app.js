// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import Hooks from "./hooks";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {
    _csrf_token: csrfToken,
    locale: Intl.NumberFormat().resolvedOptions().locale,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    timezone_offset: -new Date().getTimezoneOffset(),

    session: fetchSession(),
  },
  hooks: Hooks,
});

function fetchSession() {
  try {
    sess = JSON.parse(localStorage.getItem("session"));
    if (sess && sess.id && typeof sess.id == "string") return sess;
    new_sess = { id: genAnonId() };
    localStorage.setItem("session", JSON.stringify(new_sess));
    return new_sess;
  } catch (error) {
    new_sess = { id: genAnonId() };
    localStorage.setItem("session", JSON.stringify(new_sess));
    return new_sess;
  }
}

function genAnonId(length = 18) {
  try {
    // Generate cryptographically strong random bytes
    const arrayBuffer = new Uint8Array(length);
    window.crypto.getRandomValues(arrayBuffer);

    // Convert the array buffer to a string
    const binaryString = String.fromCharCode.apply(null, arrayBuffer);

    // Encode the string using Base64
    const base64String = btoa(binaryString);

    return base64String;
  } catch (error) {
    console.error("Error generating random Base64 string:", error);
    throw error;
  }
}

let Focus = {
  focusMain() {
    let target =
      document.querySelector("main h1") || document.querySelector("main");
    if (target) {
      let origTabIndex = target.tabIndex;
      target.tabIndex = -1;
      target.focus();
      target.tabIndex = origTabIndex;
    }
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  isFocusable(el) {
    if (
      el.tabIndex > 0 ||
      (el.tabIndex === 0 && el.getAttribute("tabIndex") !== null)
    ) {
      return true;
    }
    if (el.disabled) {
      return false;
    }

    switch (el.nodeName) {
      case "A":
        return !!el.href && el.rel !== "ignore";
      case "INPUT":
        return el.type != "hidden" && el.type !== "file";
      case "BUTTON":
      case "SELECT":
      case "TEXTAREA":
        return true;
      default:
        return false;
    }
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  attemptFocus(el) {
    if (!el) {
      return;
    }
    if (!this.isFocusable(el)) {
      return false;
    }
    try {
      el.focus();
    } catch (e) {}

    return document.activeElement === el;
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  focusFirstDescendant(el) {
    for (let i = 0; i < el.childNodes.length; i++) {
      let child = el.childNodes[i];
      if (this.attemptFocus(child) || this.focusFirstDescendant(child)) {
        return true;
      }
    }
    return false;
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  focusLastDescendant(element) {
    for (let i = element.childNodes.length - 1; i >= 0; i--) {
      let child = element.childNodes[i];
      if (this.attemptFocus(child) || this.focusLastDescendant(child)) {
        return true;
      }
    }
    return false;
  },
};

// Acessible routing -- effecting frontend changes from server-side events:
// refs:
// 1. fly.io blog post: https://fly.io/phoenix-files/server-triggered-js/
// 2. livebeats as an example: https://github.com/fly-apps/live_beats/blob/ac9780472e7019af274110a1cf71250a8d40c986/assets/js/app.js#L307
window.addEventListener("phx:js:exec", (e) => {
  liveSocket.execJS(liveSocket.main.el, e.detail.cmd);
});

window.addEventListener("js:call", (e) =>
  e.target[e.detail.call](...e.detail.args),
);
window.addEventListener("js:focus", (e) => {
  let parent = document.querySelector(e.detail.parent);
  if (parent && isVisible(parent)) {
    e.target.focus();
  }
});
window.addEventListener("js:focus-closest", (e) => {
  let el = e.target;
  let sibling = el.nextElementSibling;
  while (sibling) {
    if (isVisible(sibling) && Focus.attemptFocus(sibling)) {
      return;
    }
    sibling = sibling.nextElementSibling;
  }
  sibling = el.previousElementSibling;
  while (sibling) {
    if (isVisible(sibling) && Focus.attemptFocus(sibling)) {
      return;
    }
    sibling = sibling.previousElementSibling;
  }
  Focus.attemptFocus(el.parent) || Focus.focusMain();
});
window.addEventListener("phx:remove-el", (e) =>
  document.getElementById(e.detail.id).remove(),
);

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// Stream our server logs directly to our browser’s console
window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
  // enable server log streaming to client.
  // disable with reloader.disableServerLogs()
  reloader.enableServerLogs();
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
