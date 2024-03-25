/**
 * For utils that can't be clearly categorised yet.
 * */


/**
 * Returns true if the device is a touch device(?).
 *
 * Disclaimer: this fn may break.
 *
 * */
export function isMobileDevice() {
    var match = window.matchMedia || window.msMatchMedia;
    if(match) {
        var mq = match("(pointer:coarse)");
        return mq.matches;
    }
    return false;
}
