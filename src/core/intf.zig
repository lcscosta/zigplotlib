//! Utility Interface Functions

const std = @import("std");

const comptimePrint = std.fmt.comptimePrint;

/// Check if the given function (`Field`) is implemented for the `Actual` type.
fn checkFunctionImplementation(
    comptime Interface: type,
    comptime Field: std.builtin.Type.StructField,
    comptime Actual: type,
) void {
    const Function =  Field.type;
    const function = @typeInfo(Function);

    if (function != .@"fn") @compileError("The Interface should only contains functions (as field)");
    if (function.@"fn".is_generic) @compileError("Generic functions are not supported!");
    if (function.@"fn".is_var_args) @compileError("Variadic functions are not supported!");

    const actual = @typeInfo(Actual);
    if (actual != .@"struct") @compileError(comptimePrint("'{s}' should be a struct that implements '{s}'", .{
        @typeName(Actual),
        @typeName(Interface),
    }));

    inline for (actual.@"struct".decls) |decl| {
        if (comptime std.mem.eql(u8, decl.name, Field.name)) {
            const decl_ = @field(Actual, decl.name);
            const Decl = @TypeOf(decl_);
            const decl_info = @typeInfo(Decl);

            if (decl_info != .@"fn") @compileError(comptimePrint("Invalid Type for '{s}', should be {s}", .{
                Field.name,
                @typeName(Function),
            }));
            if (decl_info.@"fn".is_generic or decl_info.@"fn".is_var_args) @compileError(comptimePrint("Invalid Type for '{s}', should be {s}", .{
                Field.name,
                @typeName(Function),
            }));

            inline for (function.@"fn".params, decl_info.@"fn".params, 0..) |expected_param, actual_param, i| {
                if (i == 0) {
                    if (expected_param.type == *const anyopaque) {
                        if (actual_param.type != *const Actual) @compileError(comptimePrint("'self' (the 1st argument) should be of type '*const {s}'\nDefinition for '{s}':\n{s}", .{
                            @typeName(Actual),
                            Field.name,
                            @typeName(Function),
                        }));   
                        continue;
                    } else if (expected_param.type == *anyopaque) {
                        if (actual_param.type != *Actual) @compileError(comptimePrint("'self' (the 1st argument) should be of type '*{s}'\nDefinition for '{s}':\n{s}", .{
                            @typeName(Actual),
                            Field.name,
                            @typeName(Function),
                        }));   
                        continue;
                    }
                }

                if (expected_param.type != actual_param.type) @compileError(comptimePrint("arg{d} is invalid, expected: {s}, given: {s}.\nDefinition for '{s}':\n{s}", .{
                    i,
                    @typeName(expected_param.type),
                    @typeName(actual_param.type),
                    Field.name,
                    @typeName(Function),
                }));
            }

            if (function.@"fn".return_type != decl_info.@"fn".return_type) @compileError(comptimePrint("Invalid return type for '{s}', should be {s}\nDefinition for '{s}':\n{s}", .{
                Field.name,
                @typeName(Function),
                Field.name,
                @typeName(Function),
            }));

            return;
        }
    }

    @compileError(comptimePrint("'{s}' does not implement the function '{s}' and therefore does not meet the requirement of '{s}'.\nDefinition for '{s}':\n{s}", .{
        @typeName(Actual),
        Field.name,
        @typeName(Interface),
        Field.name,
        @typeName(Function),
    }));
}

/// Ensure that the `Actual` type implements the given `Interface` type.
pub fn ensureImplement(
    comptime Interface: type,
    comptime Actual: type, 
) void {
    const interface = @typeInfo(Interface);

    if (interface != .@"struct") @compileError("The Interface should be a struct containing the functions as fields");

    inline for (interface.@"struct".fields) |field| {
        checkFunctionImplementation(Interface, field, Actual);
    }
}
