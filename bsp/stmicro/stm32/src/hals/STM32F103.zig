const std = @import("std");
const peripherals = @import("microzig").chip.peripherals;
const microzig = @import("microzig");

comptime {
    //@compileLog(microzig.config.chip_name);
    for (@typeInfo(microzig.hal).Struct.fields) |i| {
        @compileLog(i.name);
    }
}


// pub const rcc_f1 = hal.blocks.rcc_f1.rcc_f1;
// pub const gpio_v1 = hal.blocks.gpio_v1.gpio_v1;
pub const gpio_v1 = @import("../blocks/gpio_v1.zig").gpio_v1;
pub const gpio_v2 = @import("../blocks/gpio_v2.zig").gpio_v2;
pub const GpioPin = @import("../blocks/common/gpio.zig").GpioPin;
// // pub const LTDC_CELL = @import("./hal/ltdc.zig").LTDC_CELL;
// // pub const SPI_CELL = @import("./hal/spi.zig").SPI_CELL;
// // pub const I2C_CELL = @import("./hal/i2c.zig").I2C_CELL;

// pub const RCC: rcc_f1 = .{ .cell = peripherals.RCC };

// pub const GPIOC: gpio_v1 = .{ .block = peripherals.GPIOC };
// pub const GPIOB: gpio_v1 = .{ .block = peripherals.GPIOB };
// pub const GPIOA: gpio_v1 = .{ .block = peripherals.GPIOA };