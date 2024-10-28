const std = @import("std");
const time = @import("../timebase.zig");

const TransactionError = @import("./common/i2c.zig").TransactionError;

pub const i2c_v1 = struct {
    block: *volatile @import("microzig").chip.types.peripherals.i2c_v1.I2C,

    fn wait_for(data: anytype, val: @TypeOf(data.*), timeout: ?*time.timer) TransactionError!void {
        while (true) {
            if (data.* == val) {
                return;
            }
            if (timeout) |timer| {
                if (timer.after()) {
                    return TransactionError.Timeout;
                }
            }
        }
    }

    pub fn write_blocking(ref: *const i2c_v1, addr: Address, src: []const u8, timeout: ?time.Duration) TransactionError!void {
        const i2c = ref.cell;
        var write_timer: time.timer = undefined;
        var timer: ?*time.timer = null;
        if (timeout) |t| {
            write_timer.set(t);
            timer = &write_timer;
        }

        errdefer { // Make sure we send the stop bit on error
            i2c.CR1.STOP = 1;
            i2c.SR1.AF = 0; // clear flag so we can check it later
        }

        i2c.CR1.POS = 0; //Disable POS (no PEC used here)

        i2c.CR1.START = 1; //Start the transfer
        try wait_for(&i2c.SR1.SB, 1, timer); //wait for it do be complete

        i2c.DR.DR = @as(u8, addr) << 1; //Write the address to the buffer.
        try wait_for(&i2c.SR1.ADDR, 1, timer); //wait for the address send complete

        if (i2c.SR1.AF == 1) { // no ack :(
            return TransactionError.NoAcknowledge;
        }
        _ = i2c.SR2; //Clears the ADDR flag by reading this

        for (src) |data| {
            try wait_for(&i2c.SR1.TxE, 1, timer);
            i2c.DR.DR = data;
            try wait_for(&i2c.SR1.BTF, 1, timer);
        }

        i2c.CR1.STOP = 1;

        //try wait_for(&i2c.SR2.BUSY, 0, &timer); //wait for it do be complete
    }

    pub fn read_blocking(ref: *const i2c_v1, addr: Address, dst: []u8, timeout: ?time.Duration) TransactionError!void {
        const i2c = ref.cell;
        var write_timer: time.timer = undefined;
        var timer: ?*time.timer = null;
        if (timeout) |t| {
            write_timer.set(t);
            timer = &write_timer;
        }

        errdefer { // Make sure we send the stop bit on error
            i2c.CR1.STOP = 1;
            i2c.SR1.AF = 0; // clear flag
        }

        i2c.CR1.POS = 0; // Disable POS (no PEC used here)

        i2c.CR1.ACK = 1; // Enable Acknowledgement
        i2c.CR1.START = 1; //Start the transfer

        try wait_for(&i2c.SR1.SB, 1, timer); //wait for it do be complete

        i2c.DR.DR = @as(u8, addr) << 1 | 1; //Write the address to the buffer.
        try wait_for(&i2c.SR1.ADDR, 1, timer); //wait for the address send complete

        // This is weird blame ST.
        switch (dst.len) {
            0 => {
                _ = i2c.SR2; //Clears the ADDR flag by reading this
                i2c.CR1.STOP = 1;
            },
            1 => {
                i2c.CR1.ACK = 0;
                _ = i2c.SR2; //Clears the ADDR flag by reading this
                i2c.CR1.STOP = 1;
            },
            2 => {
                i2c.CR1.ACK = 0;
                i2c.CR1.POS = 1;
                _ = i2c.SR2; //Clears the ADDR flag by reading this
            },
            else => {
                i2c.CR1.ACK = 1;
                _ = i2c.SR2; //Clears the ADDR flag by reading this
            },
        }

        var walker = dst;
        while (true) {
            // This is also weird blame ST.
            switch (walker.len) {
                0 => break,
                1 => {
                    try wait_for(&i2c.SR1.RxNE, 1, timer);
                    walker[0] = i2c.DR.DR;
                    break;
                },
                2 => {
                    try wait_for(&i2c.SR1.BTF, 1, timer);
                    i2c.CR1.STOP = 1;
                    walker[0] = i2c.DR.DR;
                    walker[1] = i2c.DR.DR;
                    break;
                },
                3 => {
                    try wait_for(&i2c.SR1.BTF, 1, timer);
                    i2c.CR1.ACK = 0;
                    walker[0] = i2c.DR.DR;
                    try wait_for(&i2c.SR1.BTF, 1, timer);
                    i2c.CR1.STOP = 1;
                    walker[1] = i2c.DR.DR;
                    walker[2] = i2c.DR.DR;
                    break;
                },
                else => {
                    try wait_for(&i2c.SR1.RxNE, 1, timer);
                    walker[0] = i2c.DR.DR;
                    walker = walker[1..];
                },
            }
        }

        //try wait_for(&i2c.SR2.BUSY, 0, &timer); //wait for it do be complete
    }

    pub fn write_then_read_blocking(ref: *const i2c_v1, addr: Address, src: []const u8, dst: []u8, timeout: ?time.Duration) TransactionError!void {
        try ref.write_blocking(addr, src, timeout);
        try ref.read_blocking(addr, dst, timeout);
    }
};
