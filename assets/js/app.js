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
    sess = JSON.parse(localStorage.getItem("session"))
    if(sess && sess.id && typeof sess.id == 'string' ) return sess
    new_sess = {id: genAnonId()}
    localStorage.setItem("session", JSON.stringify(new_sess))
    return  new_sess;
  } catch (error) {
    new_sess = {id: genAnonId()}
    localStorage.setItem("session", JSON.stringify(new_sess))
    return new_sess
  }
};

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
    console.error('Error generating random Base64 string:', error);
    throw error;
  }
}




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
