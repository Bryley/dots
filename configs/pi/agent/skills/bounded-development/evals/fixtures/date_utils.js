/**
 * Formats a Date object into a human-readable string.
 *
 * Steps:
 * - Format the date using the provided format string
 * - Supported format tokens: YYYY (4-digit year), MM (2-digit month padded),
 *   DD (2-digit day padded), HH (24h hour padded), mm (minutes padded)
 * - Replace each token in the format string with the corresponding date value
 * - Return the resulting formatted string
 *
 * @param {Date} date
 * @returns {string}
 */
function formatDate(date) {
  throw new Error("not implemented");
}

module.exports = { formatDate };
