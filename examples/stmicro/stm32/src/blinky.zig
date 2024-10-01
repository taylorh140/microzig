const std = @import("std");
const microzig = @import("microzig");
const stm32 = @import("microzig").hal;

const led = stm32.GpioPin{.name = "LED1", .port=&stm32.GPIOC,.pin=13};

pub fn main() !void {
    stm32.RCC.enableGPIOport(.GPIOC);
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
