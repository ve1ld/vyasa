/**
 * Contains helpers relevant to time.
 * */

/**
 * Given seconds, returns a string representing it as
 * hh:mm:ss e.g. 00:12:05
 * */
export const formatDisplayTime = (seconds) => {
  let formatted = null
  try {
    formatted = new Date(1000 * seconds).toISOString().substring(11, 19)
  } catch (e) {
    console.warn("Errored out when doing time conversions.", e)
  } finally {
    return formatted
  }
}

export const nowSeconds = () => Math.round(Date.now() / 1000)
