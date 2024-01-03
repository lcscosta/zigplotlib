//! The Area plot

const std = @import("std");
const Allocator = std.mem.Allocator;

const SVG = @import("../svg/SVG.zig");
const RGB = @import("../svg/util/rgb.zig").RGB;
const Range = @import("../util/range.zig").Range;

const Plot = @import("Plot.zig");
const FigureInfo = @import("FigureInfo.zig");

const Area = @This();

/// The Style of the Area plot
pub const Style = struct {
    /// The color of the area
    color: RGB = 0x0000FF,
    /// The opacity of the area
    opacity: f32 = 0.5,
    /// The width of the line
    width: f32 = 2.0,
};

/// The x-axis values of the area plot
x: ?[]const f32 = null,
/// The y-axis values of the area plot
y: []const f32,
/// The style of the area plot
style: Style = .{},

/// Returns the range of the x values of the line plot
pub fn get_x_range(impl: *const anyopaque) Range(f32) {
    const self: *const Area = @ptrCast(@alignCast(impl));
    if (self.x) |x| {
        const min_max = std.mem.minMax(f32, x);
        return Range(f32) {
            .min = min_max.@"0",
            .max = min_max.@"1",
        };
    } else {
        return Range(f32) {
            .min = 0.0,
            .max = @floatFromInt(self.y.len - 1),
        };
    }
}

/// Returns the range of the y values of the line plot
pub fn get_y_range(impl: *const anyopaque) Range(f32) {
    const self: *const Area = @ptrCast(@alignCast(impl));
    const min_max = std.mem.minMax(f32, self.y);
    return Range(f32) {
        .min = min_max.@"0",
        .max = min_max.@"1",
    };
}

/// The draw function for the area plot (converts the plot to SVG)
pub fn draw(impl: *const anyopaque, allocator: Allocator, svg: *SVG, info: FigureInfo) !void {
    const self: *const Area = @ptrCast(@alignCast(impl));

    if (self.x) |x_| {
        var points = std.ArrayList(f32).init(allocator);
        try points.appendSlice(&[_]f32 {0.0, info.get_base_y()});
        for (x_, self.y) |x, y| {
            const x2 = info.compute_x(x);
            const y2 = info.compute_y(y);

            try points.append(x2);
            try points.append(y2);
        }

        try points.appendSlice(&[_]f32 {info.compute_x(x_[x_.len - 1]), info.get_base_y()});
        try svg.addPolyline(.{
            .points = try points.toOwnedSlice(),
            .fill = self.style.color,
            .fill_opacity = self.style.opacity,
            .stroke = self.style.color,
            .stroke_width = .{ .pixel = self.style.width },
        });
    } else {
        var points = std.ArrayList(f32).init(allocator);
        try points.appendSlice(&[_]f32 {0.0, info.get_base_y()});
        for (self.y, 0..) |y, x| {
            const x2 = info.compute_x(@floatFromInt(x));
            const y2 = info.compute_y(y);

            try points.append(x2);
            try points.append(y2);
        }

        try points.appendSlice(&[_]f32 {info.compute_x(@floatFromInt(self.y.len - 1)), info.get_base_y()});
        try svg.addPolyline(.{
            .points = try points.toOwnedSlice(),
            .fill = self.style.color,
            .fill_opacity = self.style.opacity,
            .stroke = self.style.color,
            .stroke_width = .{ .pixel = self.style.width },
        });
    }
}

/// Converts the area plot to a plot (its interface)
pub fn interface(self: *const Area) Plot {
    return Plot.init(
        @as(*const anyopaque, self),
        &get_x_range,
        &get_y_range,
        &draw
    );
}