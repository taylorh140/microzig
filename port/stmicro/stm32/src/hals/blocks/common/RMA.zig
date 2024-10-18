const hal = @import("hal.zig");
const time = @import("timebase.zig");
const std = @import("std");

const NVIC_VECTORS = enum(i9) { NMI = -14, SysTick = -1, WWDG = 0, PVD, TAMP_STAMP, RTC_WKUP, FLASH, RCC, EXTI0, EXTI1, EXTI2, EXTI3, EXTI4, DMA1_Stream0, DMA1_Stream1, DMA1_Stream2, DMA1_Stream3, DMA1_Stream4, DMA1_Stream5, DMA1_Stream6, ADC, CAN1_TX, CAN1_RX0, CAN1_RX1, CAN1_SCE, EXTI9_5, TIM1_BRK_TIM9, TIM1_UP_TIM10, TIM1_TRG_COM_TIM11, TIM1_CC, TIM2, TIM3, TIM4, I2C1_EV, I2C1_ER, I2C2_EV, I2C2_ER, SPI1, SPI2, USART1, USART2, USART3, EXTI15_10, RTC_Alarm, OTG_FS_WKUP, TIM8_BRK_TIM12, TIM8_UP_TIM13, TIM8_TRG_COM_TIM14, TIM8_CC, DMA1_Stream7, FSMC, SDIO, TIM5, SPI3, UART4, UART5, TIM6_DAC, TIM7, DMA2_Stream0, DMA2_Stream1, DMA2_Stream2, DMA2_Stream3, DMA2_Stream4, ETH, ETH_WKUP, CAN2_TX, CAN2_RX0, CAN2_RX1, CAN2_SCE, OTG_FS, DMA2_Stream5, DMA2_Stream6, DMA2_Stream7, USART6, I2C3_EV, I2C3_ER, OTG_HS_EP1_OUT, OTG_HS_EP1_IN, OTG_HS_WKUP, OTG_HS, DCMI, CRYP, HASH_RNG, FPU, UART7, UART8, SPI4, SPI5, SPI6, SAI1, LCD_TFT, LCD_TFT_ERR, DMA2D, USER1, USER2, USER3, USER4 };
pub const Task = struct {
    period_counter: u32 = 0,
    period: u32,
    overruns: u8 = 0,
    next: ?*Task,
    isr: NVIC_VECTORS,
};

const NVIC = @import("chip.zig").devices.STM32F429.peripherals.NVIC;
const SCB = @import("chip.zig").devices.STM32F429.peripherals.SCB;

pub var TickBaseCounter: u64 = 0;

fn pendISR(isr: NVIC_VECTORS) void {
    std.debug.assert(@intFromEnum(isr) > 0);
    const isr_value: u8 = @intCast(@intFromEnum(isr));
    const word_offset = isr_value / 32;
    const bit_offset: u5 = @truncate(isr_value % 32);
    const SetField: *volatile [8]u32 = @ptrCast(&NVIC.ISPR0);
    SetField[word_offset] |= @as(u32, 1) << bit_offset;
}

fn enableISR(isr: NVIC_VECTORS) void {
    std.debug.assert(@intFromEnum(isr) > 0);
    const isr_value: u8 = @intCast(@intFromEnum(isr));
    const word_offset = isr_value / 32;
    const bit_offset: u5 = @truncate(isr_value % 32);
    const SetField: *volatile [8]u32 = @ptrCast(&NVIC.ISER0);
    SetField[word_offset] |= @as(u32, 1) << bit_offset;
}

fn SetISRPriority(isr: NVIC_VECTORS, InversePriority: u4) void {
    if (@intFromEnum(isr) > 0) {
        const isr_value: u8 = @intCast(@intFromEnum(isr));
        const word_offset = isr_value;
        const SetField: *volatile [91]u8 = @ptrCast(&NVIC.IPR0);
        SetField[word_offset] = @as(u8, InversePriority) << 4;
    } else {
        const isr_value: u8 = @intCast(-@intFromEnum(isr));
        const word_offset = isr_value;
        const SetField: *volatile [16]u8 = @ptrCast(&SCB.SHPR1); //Starts at 4,
        SetField[word_offset] = @as(u8, InversePriority) << 4;
    }
}

fn IsrIsActive(isr: NVIC_VECTORS) bool {
    std.debug.assert(@intFromEnum(isr) > 0);
    const isr_value: u8 = @intCast(@intFromEnum(isr));
    const word_offset = isr_value / 32;
    const bit_offset: u5 = @truncate(isr_value % 32);
    const ActiveField: *volatile [8]u32 = @ptrCast(&NVIC.IABR0);
    const Active = 0 != ActiveField[word_offset] & @as(u32, 1) << bit_offset;
    const PendingField: *volatile [8]u32 = @ptrCast(&NVIC.IABR0);
    const Pending = 0 != PendingField[word_offset] & @as(u32, 1) << bit_offset;
    return Active or Pending;
}
var rootTask: *volatile Task = undefined;
pub fn SetupRMA(task: *volatile Task) void {
    SetISRPriority(.SysTick, 1);
    SetISRPriority(.UART4, 2);
    SetISRPriority(.UART5, 3);

    rootTask = task;
    const STK = hal.chip.STK;
    STK.LOAD.RELOAD = time.TicksPerUs * 1000 - 1;
    STK.CTRL.CLKSOURCE = 1;
    STK.CTRL.TICKINT = 1;
    STK.CTRL.ENABLE = 1;
    enableISR(.UART4);
    enableISR(.UART5);
}

pub fn TaskA_Handle() callconv(.C) void {
    hal.GPIOG.togglePin(14);
}

pub fn TaskB_Handle() callconv(.C) void {
    hal.GPIOG.togglePin(13);
}

pub fn SysTick_Handle() callconv(.C) void {
    TickBaseCounter += @as(u64, hal.chip.STK.LOAD.RELOAD);
    Schedule(rootTask);
}

pub fn Schedule(task: *volatile Task) void {
    task.period_counter += 1;

    //task isnt scheduled to pend yet.
    if (task.period_counter < task.period) return;

    task.period_counter = 0;

    if (IsrIsActive(task.isr)) {
        task.overruns +|= 1;
        return;
    }

    pendISR(task.isr);

    if (task.next) |nextTask| {
        Schedule(nextTask);
    }
}
