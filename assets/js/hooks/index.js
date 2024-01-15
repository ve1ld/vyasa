import ShareQuoteButton from "./share_quote.js";
import {
  RenderYouTubePlayer,
  TriggerYouTubeFunction,
} from "./youtube_player.js";
import MiniPlayer from "./mini_player.js";

let Hooks = {};
Hooks.ShareQuoteButton = ShareQuoteButton;
Hooks.RenderYouTubePlayer = RenderYouTubePlayer;
Hooks.TriggerYouTubeFunction = TriggerYouTubeFunction;
Hooks.MiniPlayer = MiniPlayer;

export default Hooks;
