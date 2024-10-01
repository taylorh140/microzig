const std = @import("std");
const microzig = @import("microzig");
const pf = microzig.chip.peripherials;
const stm32 = microzig.hal;

const led = stm32.GpioPin{.name = "LED1", .port=&pf.GPIOC,.pin=13};

pub fn main() !void {
    led.set_as_output(.low);

    while (true) {
        var i: u32 = 0;
        while (i < 800_000) {
            asm volatile ("nop");
            i += 1;
        }
        led.toggle();
    }
}
