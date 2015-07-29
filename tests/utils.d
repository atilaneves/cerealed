module tests.utils;


import cerealed;
import unit_threaded;


struct SimpleStruct {
    ubyte ub;
    ushort us1;
    ushort us2;
}

void testSizeofSimpleStruct() {
    unalignedSizeof!SimpleStruct.shouldEqual(5);
}


struct Outer {
    SimpleStruct inner;
}

void testSizeOfStructWithStructs() {
    unalignedSizeof!Outer.shouldEqual(5);
}


union Union {
    ubyte ub;
    ushort us;
}

void testSizeOfUnion() {
    unalignedSizeof!Union.shouldEqual(2);
}


class Class {
    ubyte ub;
    ushort us;
}

void testSizeOfClass() {
    unalignedSizeof!Class.shouldEqual(3);
}
