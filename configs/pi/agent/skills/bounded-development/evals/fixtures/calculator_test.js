// Tests for the add function only.
// Run with: node calculator_test.js
const assert = require("assert");
const { add } = require("./calculator");

assert.strictEqual(add(1, 2), 3, "add(1, 2) should be 3");
assert.strictEqual(add(0, 0), 0, "add(0, 0) should be 0");
assert.strictEqual(add(-1, 1), 0, "add(-1, 1) should be 0");
assert.strictEqual(add(10, -5), 5, "add(10, -5) should be 5");
assert.strictEqual(add(0.1, 0.2), 0.30000000000000004, "add(0.1, 0.2) float result");

console.log("All add tests passed!");
