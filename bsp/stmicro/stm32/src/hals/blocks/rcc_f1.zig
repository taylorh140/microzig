// const RCC_t = @import("microzig").chip.types.peripherals.rcc_f1.RCC;
const RCC_t = @import("../../chips/all.zig").types.peripherals.rcc_f1.RCC;

pub const Hz = u32;

pub const Clocks = struct {
    hclk1: ?Hz,
    pclk1: ?Hz,
    pclk1_tim: ?Hz,
    pclk2: ?Hz,
    pclk2_tim: ?Hz,
    rtc: ?Hz,
    sys: ?Hz,
    usb: ?Hz,
};

pub const HseMode = enum {
    Oscillator,
    Bypass,
};

pub const Sysclk = enum(u2) {
    HSI,
    HSE,
    PLL1_P,
};

pub const Hse = struct {
    freq: Hz,
    mode: HseMode,
};

pub const PllSource = enum {
    HSE,
    HSI,
};

pub const PllPreDiv = enum(u8) {
    DIV1 = 0,
    DIV2 = 1,
};

pub const Pll = struct {
    src: PllSource,
    prediv: PllPreDiv,
    mul: PllMul,
};

pub const PllMul = enum(u8) {
    MUL2 = 0,
    MUL3 = 1,
    MUL4 = 2,
    MUL5 = 3,
    MUL6 = 4,
    MUL7 = 5,
    MUL8 = 6,
    MUL9 = 7,
    MUL10 = 8,
    MUL11 = 9,
    MUL12 = 10,
    MUL13 = 11,
    MUL14 = 12,
    MUL15 = 13,
    MUL16 = 14,
};

pub const AHBPrescaler = enum(u8) {
    DIV1 = 0,
    DIV2 = 8,
    DIV4 = 9,
    DIV8 = 10,
    DIV16 = 11,
    DIV64 = 12,
    DIV128 = 13,
    DIV256 = 14,
    DIV512 = 15,
};

pub const APBPrescaler = enum(u8) {
    DIV1 = 0,
    DIV2 = 4,
    DIV4 = 5,
    DIV8 = 6,
    DIV16 = 7,
};

pub const ADCPrescaler = enum(u8) {
    DIV2 = 0,
    DIV4 = 1,
    DIV6 = 2,
    DIV8 = 3,
};

pub const ClockMux = struct {};

pub const LseMode = enum(u8) {
    Oscillator_Low = 0,
    Oscillator_MediumLow = 1,
    Oscillator_MediumHigh = 2,
    Oscillator_High = 3,
    Bypass,
};

pub const LseConfig = struct {
    frequency: Hz,
    mode: LseMode,
};

pub const RtcClockSource = enum(u8) {
    DISABLE = 0,
    LSE = 1,
    LSI = 2,
    HSE = 3,
};

pub const LsConfig = struct {
    rtc: RtcClockSource,
    lsi: bool,
    lse: ?LseConfig,
};

pub const Config = struct {
    hsi: bool,
    hse: ?Hse,
    sys: Sysclk,
    pll: ?Pll,
    ahb_pre: AHBPrescaler,
    apb1_pre: APBPrescaler,
    apb2_pre: APBPrescaler,
    adc_pre: ADCPrescaler,
    mux: ClockMux,
    ls: LsConfig,
};

pub const rcc_f1 = extern struct {
    block: *volatile RCC_t,

    pub fn init(ref: @This(), config: Config) void {
        const RCC = ref.block;
        //Use HSI for setup as it is always available
        RCC.CR.modify(.{ .HSION = 1 });
        while (!RCC.CR.read().HSERDY) {}

        RCC.CFGR.modify(.{ .SW = .HSI });
    }

    pub fn enableGPIOport(ref: @This(), port: enum { GPIOA, GPIOB, GPIOC, GPIOD, GPIOE, GPIOF, GPIOG }) void {
        const self = ref.block;

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
