const std = @import("std");
const GPIO_t = @import("microzig").chip.types.peripherals.gpio_v1.GPIO;

pub const gpio_v1 = packed struct {
    block: *volatile GPIO_t,

    const CNF_MODE_e = enum(u4) {
        input_analog = 0b00_00,
        input_floating = 0b01_00,
        input_pushpull = 0b10_00,
        output_10Mhz_Gpo_pushpull = 0b00_01,
        output_10Mhz_Gpo_opendrain = 0b01_01,
        output_10Mhz_Af_pushpull = 0b10_01,
        output_10Mhz_Af_opendrain = 0b11_01,
        output_2Mhz_Gpo_pushpull = 0b00_10,
        output_2Mhz_Gpo_opendrain = 0b01_10,
        output_2Mhz_Af_pushpull = 0b10_10,
        output_2Mhz_Af_opendrain = 0b11_10,
        output_50Mhz_Gpo_pushpull = 0b00_11,
        output_50Mhz_Gpo_opendrain = 0b01_11,
        output_50Mhz_Af_pushpull = 0b10_11,
        output_50Mhz_Af_opendrain = 0b11_11,
    };

    /// Put the pin into input mode.
    ///
    /// The internal weak pull-up and pull-down resistors will be enabled according to `pull`.
    pub fn set_as_input(self: gpio_v1, pin: u4, pull: Pull) void {
        const block = self.block;
        const sitter: u32 = if (pull != .none) 1 else 0;
        block.BSRR.raw |= sitter << (@as(u5, pin) + if (pull == .down) 16 else 0);

        const mask: u32 = 0b1111;

        const in_word_offset = (@as(u6, pin) % 8) * 4;
        const word_offset = if (pin > 7) 1 else 0;

        const value: CNF_MODE_e = switch (pull) {
            .none => .input_floating,
            .push => .input_pushpull,
            .pull => .input_pushpull,
        };

        block.CR[word_offset].raw &= ~(mask << in_word_offset); //Mask
        block.CR[word_offset].raw |= (value << in_word_offset); //Mask
    }

    /// Put the pin into push-pull output mode.
    ///
    /// The pin level will be whatever was set before (or low by default). If you want it to begin
    /// at a specific level, call `set_high`/`set_low` on the pin first.
    ///
    /// medium an high speed rates are equivilent.
    ///
    /// The internal weak pull-up and pull-down resistors will be disabled.
    pub fn set_as_output(self: gpio_v1, pin: u4, speed: Speed) void {
        const block = self.block;

        const mask: u32 = 0b1111;

        const in_word_offset = (@as(u5, pin) % 8) * 4;
        const word_offset: u32 = if (pin > 7) 1 else 0;

        const value_e: CNF_MODE_e = switch (speed) {
            .low => .output_2Mhz_Gpo_pushpull,
            .medium => .output_10Mhz_Gpo_pushpull,
            .high => .output_10Mhz_Gpo_pushpull,
            .veryhigh => .output_50Mhz_Gpo_pushpull,
        };
        const value: u32 = @intFromEnum(value_e);

        block.CR[word_offset].raw &= ~(mask << in_word_offset); //Mask
        block.CR[word_offset].raw |= (value << in_word_offset); //Mask
    }

    pub fn is_high(self: gpio_v1, pin: u4) bool {
        const block = self.block;
        return (block.IDR.raw & (@as(u32, 1) << @as(u5, pin))) != 0;
    }

    pub fn is_low(self: gpio_v1, pin: u4) bool {
        const block = self.block;
        return (block.IDR.raw & (@as(u32, 1) << @as(u5, pin))) != 0;
    }

    pub fn set_high(self: gpio_v1, pin: u4) void {
        const block = self.block;
        block.BSRR.raw |= @as(u32, 1) << (@as(u5, pin) + 0);
    }

    pub fn set_low(self: gpio_v1, pin: u4) void {
        const block = self.block;
        block.BSRR.raw |= @as(u32, 1) << (@as(u5, pin) + 16);
    }

    pub fn toggle(self: gpio_v1, pin: u4) void {
        if (is_high(self, pin)) {
            self.set_low(pin);
        } else {
            self.set_high(pin);
        }
    }
};
