const substitution = @import("../substitution.zig");
const Substitution = substitution.Substitution;
const MonoType = substitution.MonoType;

const types = @import("types.zig");

fn monotype(s: Substitution, m: *MonoType) void {
    switch (m.*) {
        .function => |f| for (f) |*t| monotype(s, t),
        .typevar => |t| {
            if (s.get(t)) |mono| m.* = mono;
        },
        else => return,
    }
}

fn branch(s: Substitution, b: *types.Branch) void {
    for (b.arms) |*arm| {
        expression(s, &arm.condition);
        block(s, &arm.then);
    }
    block(s, &b.else_);
    monotype(s, &b.type);
}

fn binaryOp(s: Substitution, b: *types.BinaryOp) void {
    expression(s, b.left);
    expression(s, b.right);
    monotype(s, &b.type);
}

fn define(s: Substitution, d: *types.Define) void {
    monotype(s, &d.name.type);
    expression(s, d.value);
    monotype(s, &d.type);
}

fn addAssign(s: Substitution, a: *types.AddAssign) void {
    monotype(s, &a.name.type);
    expression(s, a.value);
    monotype(s, &a.type);
}

fn call(s: Substitution, c: *types.Call) void {
    expression(s, c.function);
    for (c.arguments) |*a| expression(s, a);
    monotype(s, &c.type);
}

fn intrinsic(s: Substitution, i: *types.Intrinsic) void {
    for (i.arguments) |*a| expression(s, a);
    monotype(s, &i.type);
}

fn block(s: Substitution, b: *types.Block) void {
    for (b.expressions) |*e| expression(s, e);
    monotype(s, &b.type);
}

fn group(s: Substitution, g: *types.Group) void {
    for (g.expressions) |*e| expression(s, e);
    monotype(s, &g.type);
}

fn function(s: Substitution, f: *types.Function) void {
    for (f.parameters) |*p| monotype(s, &p.type);
    monotype(s, &f.return_type);
    block(s, &f.body);
    monotype(s, &f.type);
}

fn foreignExport(s: Substitution, f: *types.ForeignExport) void {
    expression(s, f.value);
    monotype(s, &f.type);
}

pub fn expression(s: Substitution, e: *types.Expression) void {
    switch (e.*) {
        .symbol => |*sym| monotype(s, &sym.type),
        .int => |*i| monotype(s, &i.type),
        .float => |*f| monotype(s, &f.type),
        .bool => {},
        .string => {},
        .branch => |*b| branch(s, b),
        .binary_op => |*b| binaryOp(s, b),
        .define => |*d| define(s, d),
        .add_assign => |*a| addAssign(s, a),
        .call => |*c| call(s, c),
        .intrinsic => |*i| intrinsic(s, i),
        .function => |*f| function(s, f),
        .block => |*b| block(s, b),
        .group => |*g| group(s, g),
        .foreign_import => {},
        .foreign_export => |*f| foreignExport(s, f),
        .convert => {},
        .undefined => |*u| monotype(s, &u.type),
    }
}

pub fn module(s: Substitution, m: *types.Module) void {
    var iterator = m.typed.valueIterator();
    while (iterator.next()) |value_ptr| expression(s, value_ptr);
}
