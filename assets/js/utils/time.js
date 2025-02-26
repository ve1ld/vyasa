/**
 * Contains helpers relevant to time.
 * */

/**
 * Given milliseconds, returns a string representing it as

 * Formats milliseconds into a display time in the format HH:MM:SS
 * Works across all browsers and handles invalid inputs gracefully
 *
 * @param {number|string} ms - Milliseconds since epoch or date string
 * @return {string} - Formatted time string (HH:MM:SS) or fallback string
 */

/**
 * Formats milliseconds into a display time in the format HH:MM:SS
 * Works across all browsers and handles invalid inputs gracefully
 *
 * @param {number|string} ms - Milliseconds since epoch or date string
 * @return {string} - Formatted time string (HH:MM:SS) or fallback string
 */
export const formatDisplayTime = (ms) => {
  // Default fallback value
  const fallback = "--:--:--";

  // Handle empty, null, undefined inputs
  if (ms === null || ms === undefined || ms === '' || ms === Infinity) {
    return fallback;
  }

  // For numeric inputs (milliseconds since epoch)
  if (typeof ms === 'number' || (typeof ms === 'string' && !isNaN(Number(ms)))) {
    // Convert string to number if needed
    const msNum = typeof ms === 'number' ? ms : Number(ms);

    // Check if it's a valid positive number
    if (isFinite(msNum) && msNum >= 0) {
      try {
        // Calculate hours, minutes, and seconds directly from milliseconds
        const totalSeconds = Math.floor(msNum / 1000);
        const hours = String(Math.floor(totalSeconds / 3600)).padStart(2, '0');
        const minutes = String(Math.floor((totalSeconds % 3600) / 60)).padStart(2, '0');
        const seconds = String(totalSeconds % 60).padStart(2, '0');

        return `${hours}:${minutes}:${seconds}`;
      } catch (error) {
        console.warn("Error in direct millisecond calculation:", error.message);
      }
    } else {
      console.warn("Input is not a valid positive number:", msNum);
    }
  }
  // For string inputs (date strings)
  else if (typeof ms === 'string') {
    try {
      const date = new Date(ms);

      // Verify the date is valid
      if (!isNaN(date.getTime())) {
        const hours = String(date.getUTCHours()).padStart(2, '0');
        const minutes = String(date.getUTCMinutes()).padStart(2, '0');
        const seconds = String(date.getUTCSeconds()).padStart(2, '0');

        return `${hours}:${minutes}:${seconds}`;
      } else {
        console.warn("Invalid date string:", ms);
      }
    } catch (error) {
      console.warn("Error parsing date string:", error.message);
    }
  } else {
    console.warn("Unsupported input type:", typeof ms);
  }

  return fallback;
};

export const nowSeconds = () => Math.round(Date.now() / 1000)

export const nowMs = () => Date.now()
