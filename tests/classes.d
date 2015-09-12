module tests.classes;

import unit_threaded;
import cerealed.cerealiser;
import cerealed.decerealiser;

private class DummyClass {
    int i;
    bool opEquals(DummyClass d) const pure nothrow {
        return false;
    }
}

void testDummyClass() {
    auto enc = Cerealiser();
    auto dummy = new DummyClass();
    enc ~= dummy;
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
    override string toString() const {  //so it can be used in shouldEqual
        import std.conv;
        return text("ClassWithStruct(", dummy, ", ", anotherByte, ")");
    }
}

void testClassWithStruct() {
    auto enc = Cerealiser();
    auto klass = new ClassWithStruct(DummyStruct(2, 3), 4);
    enc ~= klass;
    const bytes = [2, 0, 3, 4];
    enc.bytes.shouldEqual(bytes);

    auto dec = Decerealiser(bytes);
    dec.value!ClassWithStruct.shouldEqual(klass);
}

class BaseClass {
    ubyte byte1;
    ubyte byte2;
    this(ubyte byte1, ubyte byte2) {
        this.byte1 = byte1;
        this.byte2 = byte2;
    }
}

class DerivedClass: BaseClass {
    ubyte byte3;
    ubyte byte4;
    this() { //needed for deserialisation
        this(0, 0, 0, 0);
    }
    this(ubyte byte1, ubyte byte2, ubyte byte3, ubyte byte4) {
        super(byte1, byte2);
        this.byte3 = byte3;
        this.byte4 = byte4;
    }
    override string toString() const { //so it can be used in shouldEqual
        import std.conv;
        return text("DerivedClass(", byte1, ", ", byte2, ", ", byte2, ", ", byte4, ")");
    }
}

void testDerivedClass() {
    auto enc = Cerealiser();
    auto klass = new DerivedClass(2, 4, 8, 9);
    enc ~= klass;
    const bytes = [2, 4, 8, 9];
    enc.bytes.shouldEqual(bytes);

    auto dec = Decerealiser(bytes);
    dec.value!DerivedClass.shouldEqual(klass);
}


void testSerialisationViaBaseClass() {
    BaseClass klass = new DerivedClass(2, 4, 8, 9);
    const baseBytes = [2, 4];
    const childBytes = [2, 4, 8, 9];

    auto enc = Cerealiser();
    enc ~= klass;
    enc.bytes.shouldEqual(baseBytes);

    Cerealiser.registerChildClass!DerivedClass;
    enc.reset();
    enc ~= klass;
    enc.bytes.shouldEqual(childBytes);

    auto dec = Decerealiser(childBytes);
    dec.value!DerivedClass.shouldEqual(cast(DerivedClass)klass);
}
