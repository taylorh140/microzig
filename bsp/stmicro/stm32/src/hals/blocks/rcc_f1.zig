const RCC_t = @import("microzig").chip.types.peripherals.rcc_f1.RCC;

pub const rcc_f1 = extern struct {
    cell: *volatile RCC_t,

    pub const GPIOPORT = enum {
        GPIOA,
        GPIOB,
        GPIOC,
        GPIOD,
        GPIOE,
        GPIOF,
        GPIOG,
    };

    pub fn enableGPIOport(ref: @This(), port: GPIOPORT) void {
        const self = ref.cell;

        switch (port) {
            .GPIOA => {
                self.APB2ENR.modify(.{ .GPIOAEN = 1 });
            },
            .GPIOB => {
                self.APB2ENR.modify(.{ .GPIOBEN = 1 });
            },
            .GPIOC => {
                self.APB2ENR.modify(.{ .GPIOCEN = 1 });
            },
            .GPIOD => {
                self.APB2ENR.modify(.{ .GPIODEN = 1 });
            },
            .GPIOE => {
                self.APB2ENR.modify(.{ .GPIOEEN = 1 });
            },
            .GPIOF => {
                self.APB2ENR.modify(.{ .GPIOFEN = 1 });
            },
            .GPIOG => {
                self.APB2ENR.modify(.{ .GPIOGEN = 1 });
            },
        }
    }

    pub fn enableLTDC(ref: @This()) void {
        const self = ref.cell;
        self.CR.PLLSAION = 0; //Disable PLL

        for (0..50) |_| {
            if (self.CR.PLLSAIRDY == 0) {
                break;
            }
        }

        self.PLLSAICFGR = .{
            .PLLSAIN = 192,
            .PLLSAIQ = self.PLLSAICFGR.PLLSAIQ,
            .PLLSAIR = 4,
        };

        self.DCKCFGR.PLLSAIDIVR = .by8;

        self.APB2ENR.LTDCEN = 1;
        self.CR.PLLSAION = 1; //Enable PLL

        for (0..50) |_| {
            if (self.CR.PLLSAIRDY == 1) {
                break;
            }
        }
    }

    pub fn enableDMA2D(ref: @This()) void {
        const self = ref.cell;
        self.AHB1ENR.DMA2DEN = 1;
    }
};

// comptime {
//     const A_t = packed struct(u32) { _Res1: u6 = 0, PLLSAIN: u9, _Res2: u9 = 0, PLLSAIQ: u4, PLLSAIR: u3, _Res3: u1 = 0 };
//     var A: A_t = undefined;

//     A = @bitCast(@as(u32, 0xFFFF_FFFF));
//     @compileLog(.Error, A);
//     A = .{
//         .PLLSAIN = 0,
//         .PLLSAIQ = A.PLLSAIQ,
//         .PLLSAIR = 1,
//     };
//     @compileLog(.Error, A);

//     // @compileLog(.Error, std.fmt.comptimePrint(",CSR = 0x{X}", .{@offsetOf(@This(), "CSR")}));
//     // @compileLog(.Error, std.fmt.comptimePrint(",SSCGR = 0x{X}", .{@offsetOf(@This(), "SSCGR")}));
//     // @compileLog(.Error, std.fmt.comptimePrint(",PLLI2SCFGR = 0x{X}", .{@offsetOf(RCC_CELL, "PLLI2SCFGR")}));
//     std.debug.assert(@offsetOf(RCC_CELL, "PLLSAICFGR") == 0x88);
// }
