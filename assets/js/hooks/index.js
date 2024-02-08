import ShareQuoteButton from "./share_quote.js";
import {
  RenderYouTubePlayer,
  TriggerYouTubeFunction,
} from "./youtube_player.js";
import MiniPlayer from "./mini_player.js";
import AudioPlayer from "./audio_player.js";

let Hooks = {};
Hooks.ShareQuoteButton = ShareQuoteButton;
Hooks.RenderYouTubePlayer = RenderYouTubePlayer;
Hooks.TriggerYouTubeFunction = TriggerYouTubeFunction;
Hooks.MiniPlayer = MiniPlayer;
Hooks.AudioPlayer = AudioPlayer;

export default Hooks;
