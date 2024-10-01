pub const gpio_v1 = @import("./blocks/gpio_v1.zig").gpio_v1;
pub const rcc_f1 = @import("./blocks/rcc_f1.zig").rcc_f1;

const std = @import("std");
const peripherals = @import("microzig").chip.peripherals;
const microzig = @import("microzig");


pub const GpioPin = @import("./blocks/common/gpio.zig").GpioPin;


pub const RCC: rcc_f1 = .{ .cell = peripherals.RCC };

pub const GPIOA: gpio_v1 = .{ .block = peripherals.GPIOA };
pub const GPIOB: gpio_v1 = .{ .block = peripherals.GPIOB };
pub const GPIOC: gpio_v1 = .{ .block = peripherals.GPIOC };
