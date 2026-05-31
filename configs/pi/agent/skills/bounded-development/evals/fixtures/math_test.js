// Tests for the factorial function only.
// Run with: node math_test.js
const assert = require("assert");
const { factorial } = require("./math_utils");

assert.strictEqual(factorial(0), 1, "factorial(0) should be 1");
assert.strictEqual(factorial(1), 1, "factorial(1) should be 1");
assert.strictEqual(factorial(5), 120, "factorial(5) should be 120");
assert.strictEqual(factorial(10), 3628800, "factorial(10) should be 3628800");
assert.throws(
  () => factorial(-1),
  /Error/,
  "factorial(-1) should throw an Error"
);

console.log("All factorial tests passed!");
