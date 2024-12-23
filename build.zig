const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    b.addModule("tellme", .{
        .optimize = optimize,
        .target = target,
        .root_source_file = b.path("src/root.zig"),
    });
}

const tellme = @This();

pub const a = struct {
    pub const Kind = enum {
        field,
        decl,
    };

    pub fn FieldOf(comptime T: type) type {
        return struct {
            pub const kind = Kind.field;
            pub const Type = T;
        };
    }

    pub fn DeclOf(comptime T: type) type {
        return struct {
            pub const kind = Kind.decl;
            pub const Type = T;
        };
    }
};

pub fn thatIf(comptime this: type, comptime is: type) bool {
    inline for (@typeInfo(is).@"struct".fields) |required| {
        const kind: tellme.a.Kind = comptime @field(required.type, "kind");
        const T: type = comptime @field(required.type, "Type");
        const name: [:0]const u8 = comptime required.name;

        switch (comptime kind) {
            inline .field => {
                if (comptime !@hasField(this, name)) return false;
                if (comptime @FieldType(this, name) != T) return false;
            },

            inline .decl => {
                if (comptime !@hasDecl(this, name)) return false;
                if (comptime @TypeOf(@field(this, name)) != T) return false;
            },
        }
    }
    return true;
}
pub fn thatIfVar(this: anytype, comptime is: type) bool {
    return comptime tellme.thatIf(@TypeOf(this), is);
}

fn ThatType(comptime is: type) type {
    const empty = comptime struct {};
    var fields: [
        len: {
            var i: usize = 0;
            for (@typeInfo(is).@"struct".fields) |required| {
                if (@field(required.type, "kind") == tellme.a.Kind.field) i = i + 1;
            }
            break :len i;
        }
    ]std.builtin.Type.StructField = comptime undefined;
    var count = 0;
    inline for (@typeInfo(is).@"struct".fields) |required| {
        if (comptime @field(required.type, "kind") != tellme.a.Kind.field) continue;
        fields[count] = comptime .{
            .name = required.name,
            .type = *@field(required.type, "Type"),
            .default_value = null,
            .is_comptime = false,
            .alignment = @alignOf(*@field(required.type, "Type")),
        };
        count = count + 1;
    }

    return comptime @Type(.{ .@"struct" = .{
        .fields = &fields,
        .backing_integer = @typeInfo(empty).@"struct".backing_integer,
        .decls = &.{},
        .is_tuple = @typeInfo(empty).@"struct".is_tuple,
        .layout = @typeInfo(empty).@"struct".layout,
    } });
}
pub fn that(this: anytype, comptime is: type) ThatType(is) {
    if (comptime !tellme.thatIf(@TypeOf(this.*), is)) @compileError(std.fmt.comptimePrint(
        "{s} does not implement {s}!",
        .{ @typeName(@TypeOf(this.*)), @typeName(is) },
    ));

    var ret: ThatType(is) = undefined;
    inline for (@typeInfo(is).@"struct".fields) |field| {
        if (comptime @field(field.type, "kind") != tellme.a.Kind.field) continue;
        @field(ret, field.name) = @constCast(&@field(this, field.name));
    }
    return ret;
}
