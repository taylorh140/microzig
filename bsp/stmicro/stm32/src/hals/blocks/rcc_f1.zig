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


};

