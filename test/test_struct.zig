const std = @import("std");
const wave = @import("wave");

test "tokenize struct" {
    const allocator = std.testing.allocator;
    const source =
        \\struct Person {
        \\    name: str,
        \\    age: u8,
        \\}
        \\
        \\fn start() -> Person {
        \\    {
        \\        name: "Bob",
        \\        age: 42,
        \\    }
        \\}
    ;
    const actual = try wave.testing.tokenize(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(keyword struct)
        \\(symbol Person)
        \\(delimiter '{')
        \\(new_line)
        \\(symbol name)
        \\(operator :)
        \\(symbol str)
        \\(delimiter ',')
        \\(new_line)
        \\(symbol age)
        \\(operator :)
        \\(symbol u8)
        \\(delimiter ',')
        \\(new_line)
        \\(delimiter '}')
        \\(new_line)
        \\(keyword fn)
        \\(symbol start)
        \\(delimiter '(')
        \\(delimiter ')')
        \\(operator ->)
        \\(symbol Person)
        \\(delimiter '{')
        \\(new_line)
        \\(delimiter '{')
        \\(new_line)
        \\(symbol name)
        \\(operator :)
        \\(string "Bob")
        \\(delimiter ',')
        \\(new_line)
        \\(symbol age)
        \\(operator :)
        \\(int 42)
        \\(delimiter ',')
        \\(new_line)
        \\(delimiter '}')
        \\(new_line)
        \\(delimiter '}')
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "parse struct" {
    const allocator = std.testing.allocator;
    const source =
        \\struct Person {
        \\    name: str,
        \\    age: u8,
        \\}
        \\
        \\fn start() -> Person {
        \\    {
        \\        name: "Bob",
        \\        age: 42
        \\    }
        \\}
    ;
    const actual = try wave.testing.parse(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(struct Person
        \\    name str
        \\    age u8)
        \\
        \\(fn start [] Person
        \\    {
        \\        name "Bob"
        \\        age 42
        \\    })
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "type infer struct" {
    const allocator = std.testing.allocator;
    const source =
        \\struct Person {
        \\    name: str,
        \\    age: u8,
        \\}
        \\
        \\fn start() -> Person {
        \\    {
        \\        name: "Bob",
        \\        age: 42,
        \\    }
        \\}
    ;
    const actual = try wave.testing.typeInfer(allocator, source, "start");
    defer allocator.free(actual);
    const expected =
        \\function =
        \\    name = symbol{ value = start, type = fn() -> Person }
        \\    return_type = Person
        \\    body =
        \\        struct_literal =
        \\            type = Person
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "codegen struct" {
    const allocator = std.testing.allocator;
    const source =
        \\struct Person {
        \\    name: str,
        \\    age: u8,
        \\}
        \\
        \\fn start() -> Person {
        \\    {
        \\        name: "Bob",
        \\        age: 42,
        \\    }
        \\}
    ;
    const actual = try wave.testing.codegen(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(module
        \\
        \\    (memory 1)
        \\    (export "memory" (memory 0))
        \\
        \\    (data (i32.const 0) "Bob")
        \\
        \\    (global $core/arena (mut i32) (i32.const 3))
        \\
        \\    (func $core/alloc (param $size i32) (result i32)
        \\        (local $ptr i32)
        \\        (local.tee $ptr
        \\            (global.get $core/arena))
        \\        (global.set $core/arena
        \\            (i32.add
        \\                (local.get $ptr)
        \\                (local.get $size))))
        \\
        \\    (func $start (result i32)
        \\        (local $0 i32)
        \\        (local $1 i32)
        \\        (local.set $0
        \\            (call $core/alloc
        \\                (i32.const 12)))
        \\        (local.set $1
        \\            (call $core/alloc
        \\                (i32.const 8)))
        \\        (block (result i32)
        \\            (memory.copy
        \\                (local.get $0)
        \\                (block (result i32)
        \\                    (i32.store
        \\                        (local.get $1)
        \\                        (i32.const 0))
        \\                    (i32.store
        \\                        (i32.add
        \\                            (local.get $1)
        \\                            (i32.const 4))
        \\                        (i32.const 3))
        \\                    (local.get $1))
        \\                (i32.const 8))
        \\            (i32.store8
        \\                (i32.add
        \\                    (local.get $0)
        \\                    (i32.const 8))
        \\                (i32.const 42))
        \\            (local.get $0)))
        \\
        \\    (export "_start" (func $start)))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}
