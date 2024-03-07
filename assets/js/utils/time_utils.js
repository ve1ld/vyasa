/**
 * Contains helpers relevant to time.
 * */

/**
 * Given seconds, returns a string representing it as
 * hh:mm:ss e.g. 00:12:05
 * */
export const formatDisplayTime = (ms) => {
    return new Date(ms).toISOString().substring(11, 19)
}

export const now = () => Date.now()
