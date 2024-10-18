const hal = @import("hal.zig");
const TickBaseCounter: *volatile u64 = @ptrCast(&@import("RMA.zig").TickBaseCounter);

const Ticks = u64;

pub fn readMonotonic() Ticks {
    var highRes = hal.chip.STK.VAL.CURRENT;
    var Base = TickBaseCounter.*;
    while (Base != TickBaseCounter.* or highRes < hal.chip.STK.VAL.CURRENT) {
        highRes = hal.chip.STK.VAL.CURRENT;
        Base = TickBaseCounter.*;
    }
    return Base + highRes;
}

pub const TicksPerUs = 168;

pub const duration_e = enum {
    ticks,
    us,
    ms,
    s,
    min,
};

pub const Duration = union(duration_e) {
    ticks: u64,
    us: u64,
    ms: u64,
    s: u64,
    min: u64,
};

pub const timer = struct {
    reloadTime: Ticks,
    actionTime: Ticks,

    pub fn init(dur: Duration) timer {
        var newTimer: timer = undefined;
        newTimer.reloadTime = switch (dur) {
            .ticks => |value| value,
            .us => |value| value * TicksPerUs,
            .ms => |value| value * TicksPerUs * 1000,
            .s => |value| value * TicksPerUs * 1_000_000,
            .min => |value| value * TicksPerUs * 60_000_000,
        };
        newTimer.actionTime = newTimer.reloadTime;
        return newTimer;
    }

    pub fn delay(dur: Duration) void {
        const finalTime = switch (dur) {
            .ticks => |value| value,
            .us => |value| value * TicksPerUs,
            .ms => |value| value * TicksPerUs * 1000,
            .s => |value| value * TicksPerUs * 1_000_000,
            .min => |value| value * TicksPerUs * 60_000_000,
        } + readMonotonic();

        while (readMonotonic() < finalTime) {}
    }

    pub fn set(self: *timer, dur: Duration) void {
        self.reloadTime = switch (dur) {
            .ticks => |value| value,
            .us => |value| value * TicksPerUs,
            .ms => |value| value * TicksPerUs * 1000,
            .s => |value| value * TicksPerUs * 1_000_000,
            .min => |value| value * TicksPerUs * 60_000_000,
        };
        self.reset();
    }

    pub fn reset(self: *timer) void {
        const current = readMonotonic();
        self.actionTime = current + self.reloadTime;
    }

    pub fn after(self: *const timer) bool {
        const now = readMonotonic();
        const pnt = self.actionTime;
        return now >= pnt;
    }

    pub fn every(self: *timer) bool {
        const timed_out = readMonotonic() >= self.actionTime;
        if (timed_out) {
            self.actionTime += self.reloadTime;
        }
        return timed_out;
    }
};
