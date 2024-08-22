import ShareQuoteButton from "./share_quote.js";
import {
  RenderYouTubePlayer,
  TriggerYouTubeFunction,
} from "./youtube_player.js";
import MiniPlayer from "./mini_player.js";
import MediaBridge from "./media_bridge.js";
import AudioPlayer from "./audio_player.js";
import ProgressBar from "./progress_bar.js";
import Floater from "./floater.js";
import ApplyModal from "./apply_modal.js";
import MargiNote from "./marginote.js";
import HoveRune from "./hoverune.js";
import Scrolling from "./scrolling.js";
import BrowserNavInterceptor from "./browser_nav_interceptor.js";

let Hooks = {
  ShareQuoteButton,
  RenderYouTubePlayer,
  TriggerYouTubeFunction,
  MiniPlayer,
  MediaBridge,
  AudioPlayer,
  ProgressBar,
  Floater,
  ApplyModal,
  MargiNote,
  HoveRune,
  Scrolling,
  BrowserNavInterceptor,
};

export default Hooks;
