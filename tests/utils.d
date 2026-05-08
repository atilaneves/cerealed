module tests.utils;


import cerealed;
import unit_threaded;


struct SimpleStruct {
    ubyte ub;
    ushort us1;
    ushort us2;
}

@("sizeof.simple.struct")
unittest {
    unalignedSizeof!SimpleStruct.shouldEqual(5);
}


struct Outer {
    SimpleStruct inner;
}

@("size.of.struct.with.structs")
unittest {
    unalignedSizeof!Outer.shouldEqual(5);
}


union Union {
    ubyte ub;
    ushort us;
}

@("size.of.union")
unittest {
    unalignedSizeof!Union.shouldEqual(2);
}


class Class {
    ubyte ub;
    ushort us;
}

@("size.of.class")
unittest {
    unalignedSizeof!Class.shouldEqual(3);
}
