/**
 * Calculates the factorial of a non-negative integer.
 *
 * Steps:
 * - Throw an Error('n must be non-negative') if n is negative
 * - If n is 0 or 1, return 1
 * - Otherwise, return n multiplied by the factorial of (n - 1)
 *
 * @param {number} n
 * @returns {number}
 */
function factorial(n) {
  throw new Error("not implemented");
}

/**
 * Returns the sum of an array of numbers.
 *
 * Steps:
 * - Return 0 for an empty array
 * - Sum all numbers in the array and return the result
 *
 * @param {number[]} numbers
 * @returns {number}
 */
function sumArray(numbers) {
  throw new Error("not implemented");
}

module.exports = { factorial, sumArray };
