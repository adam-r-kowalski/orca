const std = @import("std");
const zap = @import("zap");

test "tokenize template literal" {
    const allocator = std.testing.allocator;
    const source = "html`<h1>Hello World!</h1>`";
    const actual = try zap.testing.tokenize(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(symbol html)
        \\(template_literal `<h1>Hello World!</h1>`)
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "tokenize template literal with interpolation" {
    const allocator = std.testing.allocator;
    const source = "html`<h1>Hello ${name}!</h1>`";
    const actual = try zap.testing.tokenize(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(symbol html)
        \\(template_literal_begin `<h1>Hello `)
        \\(symbol name)
        \\(template_literal_end `!</h1>`)
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "tokenize template literal with two interpolations" {
    const allocator = std.testing.allocator;
    const source = "html`<h1>${x} + ${y} == ${x + y}</h1>`";
    const actual = try zap.testing.tokenize(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(symbol html)
        \\(template_literal_begin `<h1>`)
        \\(symbol x)
        \\(template_literal_middle ` + `)
        \\(symbol y)
        \\(template_literal_middle ` == `)
        \\(symbol x)
        \\(operator +)
        \\(symbol y)
        \\(template_literal_end `</h1>`)
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "parse template literal" {
    const allocator = std.testing.allocator;
    const source = "html`<h1>Hello World!</h1>`";
    const actual = try zap.testing.parse(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(template_literal
        \\    function: html
        \\    strings: [
        \\        "<h1>Hello World!</h1>"
        \\    ]
        \\    arguments: [])
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "parse template literal with interpolation" {
    const allocator = std.testing.allocator;
    const source = "html`<h1>Hello ${name}!</h1>`";
    const actual = try zap.testing.parse(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(template_literal
        \\    function: html
        \\    strings: [
        \\        "<h1>Hello "
        \\        "!</h1>"
        \\    ]
        \\    arguments: [
        \\        name
        \\    ])
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "parse template literal with two interpolations" {
    const allocator = std.testing.allocator;
    const source = "html`<h1>${x} + ${y} == ${x + y}</h1>`";
    const actual = try zap.testing.parse(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(template_literal
        \\    function: html
        \\    strings: [
        \\        "<h1>"
        \\        " + "
        \\        " == "
        \\        "</h1>"
        \\    ]
        \\    arguments: [
        \\        x
        \\        y
        \\        (+ x y)
        \\    ])
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "parse template literal no tag" {
    const allocator = std.testing.allocator;
    const source = "`<h1>Hello World!</h1>`";
    const actual = try zap.testing.parse(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(template_literal
        \\    strings: [
        \\        "<h1>Hello World!</h1>"
        \\    ]
        \\    arguments: [])
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "parse template literal with interpolation and no tag" {
    const allocator = std.testing.allocator;
    const source = "`<h1>Hello ${name}!</h1>`";
    const actual = try zap.testing.parse(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(template_literal
        \\    strings: [
        \\        "<h1>Hello "
        \\        "!</h1>"
        \\    ]
        \\    arguments: [
        \\        name
        \\    ])
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "parse template literal with two interpolations and no tag" {
    const allocator = std.testing.allocator;
    const source = "`<h1>${x} + ${y} == ${x + y}</h1>`";
    const actual = try zap.testing.parse(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(template_literal
        \\    strings: [
        \\        "<h1>"
        \\        " + "
        \\        " == "
        \\        "</h1>"
        \\    ]
        \\    arguments: [
        \\        x
        \\        y
        \\        (+ x y)
        \\    ])
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "tokenize template literal in function" {
    const allocator = std.testing.allocator;
    const source =
        \\start = fn() str {
        \\    html`<h1>Hello World!</h1>`
        \\}
    ;
    const actual = try zap.testing.tokenize(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(symbol start)
        \\(operator =)
        \\(symbol fn)
        \\(delimiter '(')
        \\(delimiter ')')
        \\(symbol str)
        \\(delimiter '{')
        \\(new_line)
        \\(symbol html)
        \\(template_literal `<h1>Hello World!</h1>`)
        \\(new_line)
        \\(delimiter '}')
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "parse template literal in function" {
    const allocator = std.testing.allocator;
    const source =
        \\start = () str {
        \\    html`<h1>Hello World!</h1>`
        \\}
    ;
    const actual = try zap.testing.parse(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(def start (fn [] str
        \\    (template_literal
        \\            function: html
        \\            strings: [
        \\                "<h1>Hello World!</h1>"
        \\            ]
        \\            arguments: [])))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

// test "type infer template literal" {
//     const allocator = std.testing.allocator;
//     const source =
//         \\start = fn() str {
//         \\    html`<h1>Hello World!</h1>`
//         \\}
//     ;
//     const actual = try zap.testing.parse(allocator, source);
//     defer allocator.free(actual);
//     const expected =
//         \\(template_literal
//         \\    function: html
//         \\    strings: [
//         \\        "<h1>Hello World!</h1>"
//         \\    ]
//         \\    arguments: [])
//     ;
//     try std.testing.expectEqualStrings(expected, actual);
// }
