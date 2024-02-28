import ShareQuoteButton from "./share_quote.js";
import {
  RenderYouTubePlayer,
  TriggerYouTubeFunction,
} from "./youtube_player.js";
import MiniPlayer from "./mini_player.js";
import MediaPlayer from "./media_player.js";
import AudioPlayer from "./audio_player.js";
import ProgressBar from "./progress_bar.js";


let Hooks = {};
Hooks.ShareQuoteButton = ShareQuoteButton;
Hooks.RenderYouTubePlayer = RenderYouTubePlayer;
Hooks.TriggerYouTubeFunction = TriggerYouTubeFunction;
Hooks.MiniPlayer = MiniPlayer;
Hooks.MediaPlayer = MediaPlayer; // TODO: probably should name this MediaBridge to correspond to its server component.
Hooks.AudioPlayer = AudioPlayer;
Hooks.ProgressBar = ProgressBar;

export default Hooks;
