module tests.compile_time;

import unit_threaded;
import cerealed;

private struct WrongStruct1 {
    @Bits!9 ubyte b;
}

private struct WrongStruct2 {
    @Bits!17 ushort b;
}

private struct RightStruct {
    @Bits!8 ubyte ub;
    @Bits!16 ushort us;
    @Bits!32 uint ui;
}

void testBitsTooBig() {
    static assert(!is(typeof(() { auto c = Cerealiser(); c ~= WrongStruct1(3); })));
    static assert(!is(typeof(() { auto c = Cerealiser(); c ~= WrongStruct2(3); })));
    static assert(is(typeof(() { auto c = Cerealiser(); c ~= RightStruct(3); })));
}
