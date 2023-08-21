const std = @import("std");
const wave = @import("wave");

test "tokenize template literal" {
    const allocator = std.testing.allocator;
    const source = "html`<h1>Hello World!</h1>`";
    const actual = try wave.testing.tokenize(allocator, source);
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
    const actual = try wave.testing.tokenize(allocator, source);
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
    const actual = try wave.testing.tokenize(allocator, source);
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
    const actual = try wave.testing.parse(allocator, source);
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
    const actual = try wave.testing.parse(allocator, source);
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
    const actual = try wave.testing.parse(allocator, source);
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
    const actual = try wave.testing.parse(allocator, source);
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
    const actual = try wave.testing.parse(allocator, source);
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
    const actual = try wave.testing.parse(allocator, source);
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
        \\fn start() -> str {
        \\    html`<h1>Hello World!</h1>`
        \\}
    ;
    const actual = try wave.testing.tokenize(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(keyword fn)
        \\(symbol start)
        \\(delimiter '(')
        \\(delimiter ')')
        \\(operator ->)
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
        \\fn start() -> str {
        \\    html`<h1>Hello World!</h1>`
        \\}
    ;
    const actual = try wave.testing.parse(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(fn start [] str
        \\    (template_literal
        \\            function: html
        \\            strings: [
        \\                "<h1>Hello World!</h1>"
        \\            ]
        \\            arguments: []))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "type infer template literal" {
    const allocator = std.testing.allocator;
    const source =
        \\fn start() -> str {
        \\    html`<h1>Hello World!</h1>`
        \\}
    ;
    const actual = try wave.testing.typeInfer(allocator, source, "start");
    defer allocator.free(actual);
    const expected =
        \\function =
        \\    name = symbol{ value = start, type = fn() -> str }
        \\    return_type = str
        \\    body =
        \\        template_literal =
        \\            function = symbol{ value = html, type = fn() -> str }
        \\            strings =
        \\                string{ value = "<h1>Hello World!</h1>", type = str }
        \\            type = str
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "type infer template literal with interpolation" {
    const allocator = std.testing.allocator;
    const source =
        \\fn start() -> str {
        \\    name = "Joe"
        \\    html`<h1>Hello ${name}!</h1>`
        \\}
    ;
    const actual = try wave.testing.typeInfer(allocator, source, "start");
    defer allocator.free(actual);
    const expected =
        \\function =
        \\    name = symbol{ value = start, type = fn() -> str }
        \\    return_type = str
        \\    body =
        \\        define =
        \\            name = symbol{ value = name, type = str }
        \\            type = void
        \\            mutable = false
        \\            value =
        \\                string{ value = "Joe", type = str }
        \\        template_literal =
        \\            function = symbol{ value = html, type = fn(str) -> str }
        \\            strings =
        \\                string{ value = "<h1>Hello ", type = str }
        \\                string{ value = "!</h1>", type = str }
        \\            arguments =
        \\                symbol{ value = name, type = str }
        \\            type = str
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "codegen template literal" {
    const allocator = std.testing.allocator;
    const source =
        \\fn start() -> str {
        \\    html`<h1>Hello World!</h1>`
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
        \\    (data (i32.const 0) "<h1>Hello World!</h1>")
        \\
        \\    (global $core/arena (mut i32) (i32.const 21))
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
        \\        (call $str
        \\            (i32.const 0)
        \\            (i32.const 21)))
        \\
        \\    (func $str (param $ptr i32) (param $len i32) (result i32)
        \\        (i32.store
        \\            (local.get $0)
        \\            (local.get $ptr))
        \\        (i32.store
        \\            (i32.add
        \\                (local.get $0)
        \\                (i32.const 4))
        \\            (local.get $len))
        \\        (local.get $0))
        \\
        \\    (export "_start" (func $start)))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "codegen template literal with new lines" {
    const allocator = std.testing.allocator;
    const source =
        \\fn start() -> str {
        \\    html`
        \\        <ul>
        \\            <li>First</li>
        \\            <li>Second</li>
        \\            <li>Third</li>
        \\        </ul>
        \\    `
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
        \\    (data (i32.const 0) "\n        <ul>\n            <li>First</li>\n            <li>Second</li>\n            <li>Third</li>\n        </ul>\n    ")
        \\
        \\    (global $core/arena (mut i32) (i32.const 114))
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
        \\        (call $str
        \\            (i32.const 0)
        \\            (i32.const 114)))
        \\
        \\    (func $str (param $ptr i32) (param $len i32) (result i32)
        \\        (i32.store
        \\            (local.get $0)
        \\            (local.get $ptr))
        \\        (i32.store
        \\            (i32.add
        \\                (local.get $0)
        \\                (i32.const 4))
        \\            (local.get $len))
        \\        (local.get $0))
        \\
        \\    (export "_start" (func $start)))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "codegen template literal with string" {
    const allocator = std.testing.allocator;
    const source =
        \\fn start() -> str {
        \\    `Hi "Joe"`
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
        \\    (data (i32.const 0) "Hi \"Joe\"")
        \\
        \\    (global $core/arena (mut i32) (i32.const 8))
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
        \\        (call $str
        \\            (i32.const 0)
        \\            (i32.const 8)))
        \\
        \\    (func $str (param $ptr i32) (param $len i32) (result i32)
        \\        (i32.store
        \\            (local.get $0)
        \\            (local.get $ptr))
        \\        (i32.store
        \\            (i32.add
        \\                (local.get $0)
        \\                (i32.const 4))
        \\            (local.get $len))
        \\        (local.get $0))
        \\
        \\    (export "_start" (func $start)))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "codegen template literal with interpolation" {
    const allocator = std.testing.allocator;
    const source =
        \\fn start() -> str {
        \\    name = "Joe"
        \\    html`<h1>Hello ${name}</h1>`
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
        \\    (data (i32.const 0) "Joe")
        \\    (data (i32.const 3) "<h1>Hello ")
        \\    (data (i32.const 13) "</h1>")
        \\
        \\    (global $core/arena (mut i32) (i32.const 18))
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
        \\        (local $name i32)
        \\        (local $1 i32)
        \\        (local $2 i32)
        \\        (local $3 i32)
        \\        (local $4 i32)
        \\        (local $5 i32)
        \\        (local $6 i32)
        \\        (local $0 i32)
        \\        (local.set $0
        \\            (call $core/alloc
        \\                (i32.const 8)))
        \\        (local.set $name
        \\            (call $str
        \\                (i32.const 0)
        \\                (i32.const 3)))
        \\        (block (result i32)
        \\            (local.set $1
        \\                (call $str
        \\                    (i32.const 3)
        \\                    (i32.const 10)))
        \\            (local.set $2
        \\                (local.get $name))
        \\            (local.set $3
        \\                (call $str
        \\                    (i32.const 13)
        \\                    (i32.const 5)))
        \\            (local.set $4
        \\                (global.get $core/arena))
        \\            (local.set $6
        \\                (i32.load
        \\                    (i32.add
        \\                        (local.get $1)
        \\                        (i32.const 4))))
        \\            (memory.copy
        \\                (local.get $4)
        \\                (i32.load
        \\                    (local.get $1))
        \\                (local.get $6))
        \\            (local.set $5
        \\                (local.get $6))
        \\            (local.set $6
        \\                (i32.load
        \\                    (i32.add
        \\                        (local.get $2)
        \\                        (i32.const 4))))
        \\            (memory.copy
        \\                (i32.add
        \\                    (local.get $4)
        \\                    (local.get $5))
        \\                (i32.load
        \\                    (local.get $2))
        \\                (local.get $6))
        \\            (local.set $5
        \\                (i32.add
        \\                    (local.get $5)
        \\                    (local.get $6)))
        \\            (local.set $6
        \\                (i32.load
        \\                    (i32.add
        \\                        (local.get $3)
        \\                        (i32.const 4))))
        \\            (memory.copy
        \\                (i32.add
        \\                    (local.get $4)
        \\                    (local.get $5))
        \\                (i32.load
        \\                    (local.get $3))
        \\                (local.get $6))
        \\            (local.set $5
        \\                (i32.add
        \\                    (local.get $5)
        \\                    (local.get $6)))
        \\            (i32.store
        \\                (local.get $0)
        \\                (local.get $4))
        \\            (i32.store
        \\                (i32.add
        \\                    (local.get $0)
        \\                    (i32.const 4))
        \\                (local.get $5))
        \\            (global.set $core/arena
        \\                (i32.add
        \\                    (local.get $4)
        \\                    (local.get $5)))
        \\            (local.get $0)))
        \\
        \\    (func $str (param $ptr i32) (param $len i32) (result i32)
        \\        (i32.store
        \\            (local.get $0)
        \\            (local.get $ptr))
        \\        (i32.store
        \\            (i32.add
        \\                (local.get $0)
        \\                (i32.const 4))
        \\            (local.get $len))
        \\        (local.get $0))
        \\
        \\    (export "_start" (func $start)))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "codegen template literal with two interpolations" {
    const allocator = std.testing.allocator;
    const source =
        \\fn start() -> str {
        \\    first = "Joe"
        \\    last = "Smith"
        \\    html`<h1>Hello ${first} ${last}</h1>`
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
        \\    (data (i32.const 0) "Joe")
        \\    (data (i32.const 3) "Smith")
        \\    (data (i32.const 8) "<h1>Hello ")
        \\    (data (i32.const 18) " ")
        \\    (data (i32.const 19) "</h1>")
        \\
        \\    (global $core/arena (mut i32) (i32.const 24))
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
        \\        (local $first i32)
        \\        (local $last i32)
        \\        (local $1 i32)
        \\        (local $2 i32)
        \\        (local $3 i32)
        \\        (local $4 i32)
        \\        (local $5 i32)
        \\        (local $6 i32)
        \\        (local $7 i32)
        \\        (local $8 i32)
        \\        (local $0 i32)
        \\        (local.set $0
        \\            (call $core/alloc
        \\                (i32.const 8)))
        \\        (local.set $first
        \\            (call $str
        \\                (i32.const 0)
        \\                (i32.const 3)))
        \\        (local.set $last
        \\            (call $str
        \\                (i32.const 3)
        \\                (i32.const 5)))
        \\        (block (result i32)
        \\            (local.set $1
        \\                (call $str
        \\                    (i32.const 8)
        \\                    (i32.const 10)))
        \\            (local.set $2
        \\                (local.get $first))
        \\            (local.set $3
        \\                (call $str
        \\                    (i32.const 18)
        \\                    (i32.const 1)))
        \\            (local.set $4
        \\                (local.get $last))
        \\            (local.set $5
        \\                (call $str
        \\                    (i32.const 19)
        \\                    (i32.const 5)))
        \\            (local.set $6
        \\                (global.get $core/arena))
        \\            (local.set $8
        \\                (i32.load
        \\                    (i32.add
        \\                        (local.get $1)
        \\                        (i32.const 4))))
        \\            (memory.copy
        \\                (local.get $6)
        \\                (i32.load
        \\                    (local.get $1))
        \\                (local.get $8))
        \\            (local.set $7
        \\                (local.get $8))
        \\            (local.set $8
        \\                (i32.load
        \\                    (i32.add
        \\                        (local.get $2)
        \\                        (i32.const 4))))
        \\            (memory.copy
        \\                (i32.add
        \\                    (local.get $6)
        \\                    (local.get $7))
        \\                (i32.load
        \\                    (local.get $2))
        \\                (local.get $8))
        \\            (local.set $7
        \\                (i32.add
        \\                    (local.get $7)
        \\                    (local.get $8)))
        \\            (local.set $8
        \\                (i32.load
        \\                    (i32.add
        \\                        (local.get $3)
        \\                        (i32.const 4))))
        \\            (memory.copy
        \\                (i32.add
        \\                    (local.get $6)
        \\                    (local.get $7))
        \\                (i32.load
        \\                    (local.get $3))
        \\                (local.get $8))
        \\            (local.set $7
        \\                (i32.add
        \\                    (local.get $7)
        \\                    (local.get $8)))
        \\            (local.set $8
        \\                (i32.load
        \\                    (i32.add
        \\                        (local.get $4)
        \\                        (i32.const 4))))
        \\            (memory.copy
        \\                (i32.add
        \\                    (local.get $6)
        \\                    (local.get $7))
        \\                (i32.load
        \\                    (local.get $4))
        \\                (local.get $8))
        \\            (local.set $7
        \\                (i32.add
        \\                    (local.get $7)
        \\                    (local.get $8)))
        \\            (local.set $8
        \\                (i32.load
        \\                    (i32.add
        \\                        (local.get $5)
        \\                        (i32.const 4))))
        \\            (memory.copy
        \\                (i32.add
        \\                    (local.get $6)
        \\                    (local.get $7))
        \\                (i32.load
        \\                    (local.get $5))
        \\                (local.get $8))
        \\            (local.set $7
        \\                (i32.add
        \\                    (local.get $7)
        \\                    (local.get $8)))
        \\            (i32.store
        \\                (local.get $0)
        \\                (local.get $6))
        \\            (i32.store
        \\                (i32.add
        \\                    (local.get $0)
        \\                    (i32.const 4))
        \\                (local.get $7))
        \\            (global.set $core/arena
        \\                (i32.add
        \\                    (local.get $6)
        \\                    (local.get $7)))
        \\            (local.get $0)))
        \\
        \\    (func $str (param $ptr i32) (param $len i32) (result i32)
        \\        (i32.store
        \\            (local.get $0)
        \\            (local.get $ptr))
        \\        (i32.store
        \\            (i32.add
        \\                (local.get $0)
        \\                (i32.const 4))
        \\            (local.get $len))
        \\        (local.get $0))
        \\
        \\    (export "_start" (func $start)))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}
