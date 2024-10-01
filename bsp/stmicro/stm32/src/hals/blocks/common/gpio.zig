const GPIO_V1 = @import("microzig").chip.types.peripherals.gpio_v1.GPIO;
const GPIO_V2 = @import("microzig").chip.types.peripherals.gpio_v2.GPIO;
const GPIO_CHIP = @TypeOf(@import("microzig").peripherals.GPOIA);

pub const Pull = enum(u2) {
    none,
    up,
    down,
};

pub const Speed = enum(u2) {
    low,
    medium,
    high,
    veryhigh,
};


// There is only one type of gpio per chip.
const GPIO_t = if(GPIO_CHIP == GPIO_V1) GPIO_V1 else GPIO_V2;


pub const GpioPin = struct {
    name: []const u8,
    port: *const GPIO_t,
    pin: u4,

    pub fn set_as_input(self: GpioPin, pull: Pull) void {
        self.port.set_as_input(self.pin, pull);
    }

    pub fn set_as_output(self: GpioPin, speed: Speed) void {
        self.port.set_as_output(self.pin, speed);
    }

    pub fn toggle(self: GpioPin) void {
        self.port.toggle(self.pin);
    }
};
