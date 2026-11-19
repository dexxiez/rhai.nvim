//! Module docs for the sample script.

import "utils" as utils;

/// Adds two numbers together.
fn add(a, b) {
    a + b
}

const LIMIT = 10;
let total = 0;
let name = "world";
let greeting = `hello ${name}!`;
let flag = true;
let ch = 'x';
let ratio = 1.5;

for i in 0..LIMIT {
    if i % 2 == 0 {
        total += add(i, 1);
    } else {
        continue;
    }
}

let obj = #{ answer: 42, "quoted key": [1, 2, 3] };
let doubled = |x| x * 2;

let kind = switch total {
    0 => "zero",
    _ => "many",
};

/* block comment */
while total > 0 {
    total -= 1;
}

try {
    throw "oops";
} catch (err) {
    print(err);
}

obj.answer.to_string();
utils::helper(doubled.call(2));
