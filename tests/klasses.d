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
    this() {
    }
    this(DummyStruct d, ubyte a) {
        dummy = d;
        anotherByte = a;
    }
    override string toString() const {
        import std.conv;
        return text("ClassWithStruct(", dummy, ", ", anotherByte, ")");
    }
}

void testClassWithStruct() {
    auto enc = new Cerealiser();
    auto klass = new ClassWithStruct(DummyStruct(2, 3), 4);
    enc ~= klass;
    const bytes = [2, 0, 3, 4];
    checkEqual(enc.bytes, bytes);

    auto dec = new Decerealiser(bytes);
    checkEqual(dec.value!ClassWithStruct, klass);
}
