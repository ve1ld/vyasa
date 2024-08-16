/**
 * This file contains definitions for custom event bridges and keeps
 * the exporting of these clean.
 * */

import { bridged } from "./bridged.js";

export const seekTimeBridge = bridged("seekTime");
export const playPauseBridge = bridged("playPause");
export const heartbeatBridge = bridged("heartbeat");
/**
 * The playbackMetaBridge is the channel through which playback-metadata related
 * messages are passed.
 * An example would be when a voice first gets loaded/registered and we can
 * update the mediasessions api even if the user has not started the actual playback.
 * */
export const playbackMetaBridge = bridged("playback");
