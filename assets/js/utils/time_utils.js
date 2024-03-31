/**
 * Contains helpers relevant to time.
 * */

/**
 * Given milliseconds, returns a string representing it as
 * hh:mm:ss e.g. 00:12:05
 * */
export const formatDisplayTime = (ms) => {
  let formatted = null
  try {
    formatted = new Date(ms).toISOString().substring(11, 19)
  } catch (e) {
    console.warn("Errored out when doing time conversions.", e)
  } finally {
    return formatted
  }
}

export const nowSeconds = () => Math.round(Date.now() / 1000)

export const nowMs = () => Date.now()
