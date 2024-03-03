import ShareQuoteButton from "./share_quote.js";
import {
  RenderYouTubePlayer,
  TriggerYouTubeFunction,
} from "./youtube_player.js";
import MiniPlayer from "./mini_player.js";
import MediaPlayer from "./media_player.js";
import AudioPlayer from "./audio_player.js";
import ProgressBar from "./progress_bar.js";
import Floater from "./floater.js"


let Hooks = {
  ShareQuoteButton,
  RenderYouTubePlayer,
  TriggerYouTubeFunction,
  MiniPlayer,
  MediaPlayer, // TODO: probably should name this MediaBridge to correspond to its server component.
  AudioPlayer,
  ProgressBar,
  Floater,
};

export default Hooks;
