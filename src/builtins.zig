const interner = @import("interner.zig");
const Intern = interner.Intern;
const Interned = interner.Interned;

pub const Builtins = struct {
    import: Interned,
    export_: Interned,
    i32: Interned,
    f32: Interned,
    bool: Interned,
    if_: Interned,
    then: Interned,
    else_: Interned,
    true_: Interned,
    false_: Interned,

    pub fn init(intern: *Intern) !Builtins {
        return Builtins{
            .import = try interner.store(intern, "import"),
            .export_ = try interner.store(intern, "export"),
            .i32 = try interner.store(intern, "i32"),
            .f32 = try interner.store(intern, "f32"),
            .bool = try interner.store(intern, "bool"),
            .if_ = try interner.store(intern, "if"),
            .then = try interner.store(intern, "then"),
            .else_ = try interner.store(intern, "else"),
            .true_ = try interner.store(intern, "true"),
            .false_ = try interner.store(intern, "false"),
        };
    }
};
