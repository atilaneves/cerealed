module tests.classes;

import unit_threaded.check;
import cerealed.cereal;
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
    override string toString() const {  //so it can be used in checkEqual
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

class BaseClass {
    ubyte byte1;
    ubyte byte2;
    this() { } //needed for deserialisation
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
    override string toString() const { //so it can be used in checkEqual
        import std.conv;
        return text("DerivedClass(", byte1, ", ", byte2, ", ", byte2, ", ", byte4, ")");
    }
}

void testDerivedClass() {
    auto enc = new Cerealiser();
    auto klass = new DerivedClass(2, 4, 8, 9);
    enc ~= klass;
    const bytes = [2, 4, 8, 9];
    checkEqual(enc.bytes, bytes);

    auto dec = new Decerealiser(bytes);
    checkEqual(dec.value!DerivedClass, klass);
}


void testSerialisationViaBaseClass() {
    BaseClass klass = new DerivedClass(2, 4, 8, 9);
    const baseBytes = [2, 4];
    const childBytes = [2, 4, 8, 9];

    auto enc = new Cerealiser;
    enc ~= klass;
    checkEqual(enc.bytes, baseBytes);

    Cereal.registerChildClass!DerivedClass;
    enc.reset();
    enc ~= klass;
    checkEqual(enc.bytes, childBytes);

    auto dec = new Decerealiser(childBytes);
    checkEqual(dec.value!DerivedClass, cast(DerivedClass)klass);
}
