const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;

const Interned = @import("../interner.zig").Interned;
const Builtins = @import("../builtins.zig").Builtins;
const constraints = @import("../constraints.zig");
const Constraints = constraints.Constraints;
const Equal = constraints.Equal;
const substitution = @import("../substitution.zig");
const MonoType = substitution.MonoType;
const TypeVar = substitution.TypeVar;
const types = @import("types.zig");
const parser = @import("../parser.zig");

const Context = struct {
    allocator: Allocator,
    builtins: Builtins,
    constraints: *Constraints,
    scopes: *types.Scopes,
};

fn symbol(scopes: types.Scopes, s: parser.types.Symbol) !types.Symbol {
    const binding = try scopes.find(s);
    return types.Symbol{
        .value = s.value,
        .span = s.span,
        .type = binding.type,
        .mutable = binding.mutable,
        .global = binding.global,
    };
}

fn int(context: Context, i: parser.types.Int) types.Int {
    return types.Int{
        .value = i.value,
        .span = i.span,
        .type = context.constraints.freshTypeVar(),
    };
}

fn float(context: Context, f: parser.types.Float) types.Float {
    return types.Float{
        .value = f.value,
        .span = f.span,
        .type = context.constraints.freshTypeVar(),
    };
}

fn string(context: Context, s: parser.types.String) !types.String {
    const element_type = try context.allocator.create(MonoType);
    element_type.* = .u8;
    return types.String{
        .value = s.value,
        .span = s.span,
        .type = .{ .array = .{ .size = null, .element_type = element_type } },
    };
}

fn boolean(b: parser.types.Bool) types.Bool {
    return types.Bool{
        .value = b.value,
        .span = b.span,
        .type = .bool,
    };
}

fn untypedUndefined(context: Context, u: parser.types.Undefined) types.Undefined {
    return types.Undefined{
        .span = u.span,
        .type = context.constraints.freshTypeVar(),
    };
}

fn branch(context: Context, b: parser.types.Branch) !types.Branch {
    const arms = try context.allocator.alloc(types.Arm, b.arms.len);
    const result_type = context.constraints.freshTypeVar();
    for (arms, b.arms) |*typed_arm, untyped_arm| {
        const condition = try expression(context, untyped_arm.condition);
        const then = try block(context, untyped_arm.then);
        typed_arm.* = types.Arm{ .condition = condition, .then = then };
        try context.constraints.equal.appendSlice(&[_]Equal{
            .{
                .left = .{ .type = condition.typeOf(), .span = condition.span() },
                .right = .{ .type = .bool, .span = null },
            },
            .{
                .left = .{ .type = then.type, .span = then.span },
                .right = .{ .type = result_type, .span = null },
            },
        });
    }
    const else_ = try block(context, b.else_);
    try context.constraints.equal.append(.{
        .left = .{ .type = else_.type, .span = else_.span },
        .right = .{ .type = result_type, .span = null },
    });
    return types.Branch{
        .arms = arms,
        .else_ = else_,
        .type = result_type,
        .span = b.span,
    };
}

fn dotCall(context: Context, b: parser.types.BinaryOp) !types.Expression {
    switch (b.right.*) {
        .call => |c| {
            const arguments = try context.allocator.alloc(parser.types.Expression, c.arguments.len + 1);
            arguments[0] = b.left.*;
            @memcpy(arguments[1..], c.arguments);
            const new_call = parser.types.Call{
                .function = c.function,
                .arguments = arguments,
                .span = b.span,
            };
            return try call(context, new_call);
        },
        else => |k| std.debug.panic("Expected call after dot, got {}", .{k}),
    }
}

fn binaryOp(context: Context, b: parser.types.BinaryOp) !types.Expression {
    switch (b.kind) {
        .dot => return dotCall(context, b),
        .equal, .greater, .less => {
            const left = try expressionAlloc(context, b.left.*);
            const right = try expressionAlloc(context, b.right.*);
            try context.constraints.equal.append(.{
                .left = .{ .type = left.typeOf(), .span = parser.span.expression(b.left.*) },
                .right = .{ .type = right.typeOf(), .span = parser.span.expression(b.right.*) },
            });
            return types.Expression{
                .binary_op = .{
                    .kind = b.kind,
                    .left = left,
                    .right = right,
                    .span = b.span,
                    .type = .bool,
                },
            };
        },
        else => {
            const left = try expressionAlloc(context, b.left.*);
            const right = try expressionAlloc(context, b.right.*);
            const left_typed_span = .{ .type = left.typeOf(), .span = parser.span.expression(b.left.*) };
            try context.constraints.equal.append(.{
                .left = left_typed_span,
                .right = .{ .type = right.typeOf(), .span = parser.span.expression(b.right.*) },
            });
            const tvar = context.constraints.freshTypeVar();
            try context.constraints.equal.append(.{
                .left = left_typed_span,
                .right = .{ .type = tvar, .span = null },
            });
            return types.Expression{
                .binary_op = .{
                    .kind = b.kind,
                    .left = left,
                    .right = right,
                    .span = b.span,
                    .type = tvar,
                },
            };
        },
    }
}

fn define(context: Context, d: parser.types.Define) !types.Define {
    const value = try expressionAlloc(context, d.value.*);
    var monotype = value.typeOf();
    if (d.type) |t| {
        const annotated_type = try types.expressionToMonoType(context.allocator, context.builtins, t.*);
        try context.constraints.equal.append(.{
            .left = .{ .type = annotated_type, .span = parser.span.expression(t.*) },
            .right = .{ .type = monotype, .span = parser.span.expression(d.value.*) },
        });
        monotype = annotated_type;
    }
    const binding = types.Binding{
        .type = monotype,
        .global = false,
        .mutable = false,
    };
    const name = types.Symbol{
        .value = d.name.value,
        .span = d.span,
        .type = monotype,
        .global = false,
        .mutable = false,
    };
    try context.scopes.put(name.value, binding);
    return types.Define{
        .name = name,
        .value = value,
        .span = d.span,
        .mutable = d.mutable,
        .type = .void,
    };
}

fn addAssign(context: Context, d: parser.types.AddAssign) !types.AddAssign {
    const value = try expressionAlloc(context, d.value.*);
    var monotype = value.typeOf();
    const binding = types.Binding{
        .type = monotype,
        .global = false,
        .mutable = false,
    };
    const name = types.Symbol{
        .value = d.name.value,
        .span = d.span,
        .type = monotype,
        .global = false,
        .mutable = false,
    };
    try context.scopes.put(name.value, binding);
    return types.AddAssign{
        .name = name,
        .value = value,
        .span = d.span,
        .type = .void,
    };
}

fn callForeignImport(context: Context, c: parser.types.Call) !types.Expression {
    if (c.arguments.len != 3) std.debug.panic("foreign_import takes 3 arguments", .{});
    const monotype = try types.expressionToMonoType(context.allocator, context.builtins, c.arguments[2]);
    return types.Expression{
        .foreign_import = .{
            .module = c.arguments[0].string.value,
            .name = c.arguments[1].string.value,
            .span = c.span,
            .type = monotype,
        },
    };
}

fn callForeignExport(context: Context, c: parser.types.Call) !types.Expression {
    if (c.arguments.len != 2) std.debug.panic("foreign_export takes 2 arguments", .{});
    return types.Expression{
        .foreign_export = .{
            .name = c.arguments[0].string.value,
            .value = try expressionAlloc(context, c.arguments[1]),
            .span = c.span,
            .type = .void,
        },
    };
}

fn callConvert(context: Context, c: parser.types.Call) !types.Expression {
    if (c.arguments.len != 2) std.debug.panic("convert takes 2 arguments", .{});
    const monotype = try types.expressionToMonoType(context.allocator, context.builtins, c.arguments[1]);
    return types.Expression{
        .convert = .{
            .value = try expressionAlloc(context, c.arguments[0]),
            .span = c.span,
            .type = monotype,
        },
    };
}

fn callSqrt(context: Context, c: parser.types.Call) !types.Expression {
    if (c.arguments.len != 1) std.debug.panic("sqrt takes 1 arguments", .{});
    const arguments = try context.allocator.alloc(types.Expression, 1);
    arguments[0] = try expression(context, c.arguments[0]);
    return types.Expression{
        .intrinsic = .{
            .function = context.builtins.sqrt,
            .arguments = arguments,
            .span = c.span,
            .type = arguments[0].typeOf(),
        },
    };
}

fn call(context: Context, c: parser.types.Call) !types.Expression {
    switch (c.function.*) {
        .symbol => |s| {
            const len = c.arguments.len;
            const function_type = try context.allocator.alloc(MonoType, len + 1);
            if (s.value.eql(context.builtins.foreign_import)) return try callForeignImport(context, c);
            if (s.value.eql(context.builtins.foreign_export)) return try callForeignExport(context, c);
            if (s.value.eql(context.builtins.convert)) return try callConvert(context, c);
            if (s.value.eql(context.builtins.sqrt)) return try callSqrt(context, c);
            const f = try symbol(context.scopes.*, s);
            const arguments = try context.allocator.alloc(types.Expression, len);
            for (c.arguments, arguments, function_type[0..len]) |untyped_arg, *typed_arg, *t| {
                typed_arg.* = try expression(context, untyped_arg);
                t.* = typed_arg.typeOf();
            }
            const return_type = context.constraints.freshTypeVar();
            function_type[len] = return_type;
            try context.constraints.equal.append(.{
                .left = .{ .type = f.type, .span = f.span },
                .right = .{ .type = .{ .function = function_type }, .span = null },
            });
            return types.Expression{
                .call = .{
                    .function = try alloc(context.allocator, .{ .symbol = f }),
                    .arguments = arguments,
                    .span = c.span,
                    .type = return_type,
                },
            };
        },
        else => |k| std.debug.panic("\nInvalid call function type {}", .{k}),
    }
}

fn function(context: Context, f: parser.types.Function) !types.Function {
    try context.scopes.push();
    defer context.scopes.pop();
    const len = f.parameters.len;
    const parameters = try context.allocator.alloc(types.Symbol, len);
    const function_type = try context.allocator.alloc(MonoType, len + 1);
    for (f.parameters, parameters, function_type[0..len]) |untyped_p, *typed_p, *t| {
        const name_symbol = untyped_p.name.value;
        const p_type = try types.expressionToMonoType(context.allocator, context.builtins, untyped_p.type);
        const span = parser.types.Span{
            .begin = untyped_p.name.span.begin,
            .end = parser.span.expression(untyped_p.type).end,
        };
        const binding = types.Binding{
            .type = p_type,
            .global = false,
            .mutable = false,
        };
        typed_p.* = types.Symbol{
            .value = name_symbol,
            .span = span,
            .type = p_type,
            .global = false,
            .mutable = false,
        };
        try context.scopes.put(name_symbol, binding);
        t.* = p_type;
    }
    const return_type = try types.expressionToMonoType(context.allocator, context.builtins, f.return_type.*);
    const body = try block(context, f.body);
    try context.constraints.equal.append(.{
        .left = .{ .type = return_type, .span = parser.span.expression(f.return_type.*) },
        .right = .{ .type = body.type, .span = body.span },
    });
    function_type[len] = return_type;
    return types.Function{
        .parameters = parameters,
        .return_type = return_type,
        .body = body,
        .span = f.span,
        .type = .{ .function = function_type },
    };
}

fn block(context: Context, b: parser.types.Block) !types.Block {
    const len = b.expressions.len;
    const expressions = try context.allocator.alloc(types.Expression, len);
    for (b.expressions, expressions) |untyped_e, *typed_e| {
        typed_e.* = try expression(context, untyped_e);
    }
    const monotype = if (len == 0) .void else expressions[len - 1].typeOf();
    return types.Block{
        .expressions = expressions,
        .span = b.span,
        .type = monotype,
    };
}

fn expression(context: Context, e: parser.types.Expression) error{ OutOfMemory, CompileError }!types.Expression {
    switch (e) {
        .int => |i| return .{ .int = int(context, i) },
        .float => |f| return .{ .float = float(context, f) },
        .string => |s| return .{ .string = try string(context, s) },
        .symbol => |s| return .{ .symbol = try symbol(context.scopes.*, s) },
        .bool => |b| return .{ .bool = boolean(b) },
        .define => |d| return .{ .define = try define(context, d) },
        .add_assign => |a| return .{ .add_assign = try addAssign(context, a) },
        .function => |f| return .{ .function = try function(context, f) },
        .binary_op => |b| return try binaryOp(context, b),
        .block => |b| return .{ .block = try block(context, b) },
        .branch => |b| return .{ .branch = try branch(context, b) },
        .call => |c| return try call(context, c),
        .undefined => |u| return .{ .undefined = untypedUndefined(context, u) },
        else => |k| std.debug.panic("\nUnsupported expression {}", .{k}),
    }
}

fn alloc(allocator: Allocator, expr: types.Expression) !*types.Expression {
    const result = try allocator.create(types.Expression);
    result.* = expr;
    return result;
}

fn expressionAlloc(context: Context, expr: parser.types.Expression) !*types.Expression {
    return try alloc(context.allocator, try expression(context, expr));
}

pub fn topLevel(module: *types.Module, name: Interned) !void {
    var work_queue = types.WorkQueue.init(module.allocator);
    try work_queue.append(name);
    while (work_queue.items.len != 0) {
        const current = work_queue.pop();
        if (module.untyped.fetchRemove(current)) |entry| {
            var scopes = try types.Scopes.init(module.allocator, module.scope, &work_queue, module.compile_errors);
            const context = Context{
                .allocator = module.allocator,
                .builtins = module.builtins,
                .constraints = module.constraints,
                .scopes = &scopes,
            };
            const expr = try expression(context, entry.value);
            try module.typed.putNoClobber(current, expr);
        }
    }
}
