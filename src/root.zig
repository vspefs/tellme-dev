// Copyright (C) 2024 vspefs <vspefs@protonmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");
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
        if (comptime @hasDecl(required.type, "kind")) {
            if (comptime @TypeOf(@field(required.type, "kind")) == tellme.a.Kind) {
                // the right path!
            } else {
                continue;
            }
        } else {
            continue;
        }
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
                if (@hasDecl(required.type, "kind")) {
                    if (@TypeOf(@field(required.type, "kind")) == tellme.a.Kind) {
                        // the right path!
                    } else {
                        continue;
                    }
                } else {
                    continue;
                }
                if (@field(required.type, "kind") == tellme.a.Kind.field) i = i + 1;
            }
            break :len i;
        }
    ]std.builtin.Type.StructField = comptime undefined;
    var count = 0;
    inline for (@typeInfo(is).@"struct".fields) |required| {
        if (comptime @hasDecl(required.type, "kind")) {
            if (comptime @TypeOf(@field(required.type, "kind")) == tellme.a.Kind) {
                if (comptime @field(required.type, "kind") == tellme.a.Kind.field) {
                    // the right path!
                } else {
                    continue;
                }
            } else {
                continue;
            }
        } else {
            continue;
        }
        fields[count] = comptime .{
            .name = required.name,
            .type = *@field(required.type, "Type"),
            .default_value_ptr = null,
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
/// You should pass a pointer in!
pub fn that(this: anytype, comptime is: type) ThatType(is) {
    if (comptime !tellme.thatIf(@TypeOf(this.*), is)) @compileError(std.fmt.comptimePrint(
        "{s} does not implement {s}!",
        .{ @typeName(@TypeOf(this.*)), @typeName(is) },
    ));

    var ret: ThatType(is) = undefined;
    inline for (@typeInfo(@TypeOf(ret)).@"struct".fields) |field| {
        @field(ret, field.name) = @constCast(&@field(this, field.name));
    }
    return ret;
}
