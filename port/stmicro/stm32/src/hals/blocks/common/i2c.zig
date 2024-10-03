pub const TransactionError = error{
    DeviceNotPresent,
    NoAcknowledge,
    Timeout,
    TargetAddressReserved,
    NoData,
    TxFifoFlushed,
    UnknownAbort,
};


pub const Address = u7;