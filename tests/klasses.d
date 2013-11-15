module tests.klasses;

import unit_threaded.check;
import cerealed.cerealiser;
import cerealed.decerealiser;
import core.exception;

private class DummyClass {
    int i;
    bool opEquals(DummyClass d) const pure nothrow {
        return false;
    }
}

void testDummyClass() {
    auto enc = new Cerealiser();
    auto dummy = new DummyClass();
    enc ~= dummy;

    auto dec = new Decerealiser(enc.bytes);
}

private struct DummyStruct {
    ubyte first;
    ushort second;
}

private class ClassWithStruct {
    DummyStruct dummy;
    ubyte anotherByte;
    this(DummyStruct d, ubyte a) {
        dummy = d;
        anotherByte = a;
    }
}

void testClassWithStruct() {
    auto cereal = new Cerealiser();
    cereal ~= new ClassWithStruct(DummyStruct(2, 3), 4);
    checkEqual(cereal.bytes, [2, 0, 3, 4]);
}
