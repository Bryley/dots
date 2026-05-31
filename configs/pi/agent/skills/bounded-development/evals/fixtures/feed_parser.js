/**
 * Parses an RSS feed XML string and extracts article titles.
 *
 * Steps:
 * - Parse xmlString as XML
 * - Find all <title> elements that are direct children of <item> elements
 * - Return their text content as an array of strings
 * - Return an empty array if no <item> elements are found
 *
 * @param {string} xmlString
 * @returns {string[]}
 */
function parseRssTitles(xmlString) {
  throw new Error("not implemented");
}

module.exports = { parseRssTitles };
