/* Proxy configuration for SerialImplP, wiring the CPUResource */
configuration SerialP {

  provides {
    interface Init;
    interface SplitControl;
    interface SendBytePacket;
    interface ReceiveBytePacket;
  }

  uses {
    interface SerialFrameComm;
    interface Leds;
    interface StdControl as SerialControl;
    interface SerialFlush;
  }
}
implementation {

    components SerialImplP as Impl;
    Init = Impl;
    SplitControl = Impl;
    SendBytePacket = Impl;
    ReceiveBytePacket = Impl;
    
    SerialFrameComm = Impl;
    Leds = Impl;
    SerialControl = Impl;
    SerialFlush = Impl;

    components QuantoResourcesC;
    Impl.CPUResource -> QuantoResourcesC.CPUResource; 
}
