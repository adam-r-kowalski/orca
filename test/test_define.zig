const std = @import("std");
const fusion = @import("fusion");

test "tokenize single line define" {
    const allocator = std.testing.allocator;
    const source =
        \\x = y + z
    ;
    var intern = fusion.Intern.init(allocator);
    defer intern.deinit();
    const tokens = try fusion.tokenizer.tokenize(allocator, &intern, source);
    defer tokens.deinit();
    const actual = try fusion.tokenizer.toString(allocator, intern, tokens);
    defer allocator.free(actual);
    const expected =
        \\symbol x
        \\equal
        \\symbol y
        \\plus
        \\symbol z
    ;
    try std.testing.expectEqualStrings(expected, actual);
    const reconstructed = try fusion.tokenizer.toSource(allocator, intern, tokens);
    defer allocator.free(reconstructed);
    try std.testing.expectEqualStrings(source, reconstructed);
}

test "parse single line define" {
    const allocator = std.testing.allocator;
    const source =
        \\x = y + z
    ;
    var intern = fusion.Intern.init(allocator);
    defer intern.deinit();
    const tokens = try fusion.tokenizer.tokenize(allocator, &intern, source);
    defer tokens.deinit();
    const ast = try fusion.parser.parse(allocator, tokens);
    defer ast.deinit();
    const actual = try fusion.parser.toString(allocator, intern, ast);
    defer allocator.free(actual);
    const expected =
        \\(def x (+ y z))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "tokenize annotated single line define" {
    const allocator = std.testing.allocator;
    const source =
        \\x: I32 = y + z
    ;
    var intern = fusion.Intern.init(allocator);
    defer intern.deinit();
    const tokens = try fusion.tokenizer.tokenize(allocator, &intern, source);
    defer tokens.deinit();
    const actual = try fusion.tokenizer.toString(allocator, intern, tokens);
    defer allocator.free(actual);
    const expected =
        \\symbol x
        \\colon
        \\symbol I32
        \\equal
        \\symbol y
        \\plus
        \\symbol z
    ;
    try std.testing.expectEqualStrings(expected, actual);
    const reconstructed = try fusion.tokenizer.toSource(allocator, intern, tokens);
    defer allocator.free(reconstructed);
    try std.testing.expectEqualStrings(source, reconstructed);
}

test "parse single line define" {
    const allocator = std.testing.allocator;
    const source =
        \\x: I32 = y + z
    ;
    var intern = fusion.Intern.init(allocator);
    defer intern.deinit();
    const tokens = try fusion.tokenizer.tokenize(allocator, &intern, source);
    defer tokens.deinit();
    const ast = try fusion.parser.parse(allocator, tokens);
    defer ast.deinit();
    const actual = try fusion.parser.toString(allocator, intern, ast);
    defer allocator.free(actual);
    const expected =
        \\(def x I32 (+ y z))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}