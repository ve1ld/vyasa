/**
 * This file is for helpers to interface with the WebShare API.
 *
 * Ref: https://developer.mozilla.org/en-US/docs/Web/API/Web_Share_API
 */

const sharers = {
  "file": shareFile, // to assign to window.shareContent
  "url": shareUrl, // to assign to window.shareUrl
};

/**
 * Returns a function that can be used to set various webshare api attributes.
 */
export function getSharer(sharingType, ...args) {
  if (!checkBrowserSupport()) {
    console.warning(`This browser doesn't support shares like that, please copy the url instead.`);
    return null;
  }
  if (!(sharingType in sharers)) {
    console.warning(`$Sharing Type of {sharingType} is not supported yet.`);
    return null;
  }

  return () => sharers[sharingType](...args);
}

function shareFile(title, url) {
  if (navigator.share) {
    navigator.share({
      title: title,
      url: url,
    })
      .then(() => console.log("Successful share"))
      .catch((error) => console.log("Error sharing", error));
  } else {
    console.info(`Your system doesn't support sharing files.`);
  }
}

function shareUrl(url) {
  if (navigator.share) {
    navigator.share({
      url: url,
    })
      .then(() => console.log("Successful share"))
      .catch((error) => console.log("Error sharing", error));
  } else {
    console.info(`Your system doesn't support sharing urls.`);
  }
}

/**
 * Returns true if the browser supports the navigator.share function, false otherwise.
 * */
function checkBrowserSupport() {
  // TODO: implement this
  return true

}
