module tests.pointers;

import unit_threaded;
import cerealed;
import core.exception;


private struct InnerStruct {
    ubyte b;
    ushort s;
}

private struct OuterStructWithPointerToStruct {
    ushort s;
    InnerStruct* inner;
    ubyte b;
}

void testStructWithPointerToStruct() {
    auto enc = Cerealiser();
    //outer not const because not copyable from const
    auto outer = OuterStructWithPointerToStruct(3, new InnerStruct(7, 2), 5);
    enc ~= outer;

    const bytes = [ 0, 3, 7, 0, 2, 5];
    checkEqual(enc.bytes, bytes);

    auto dec = Decerealiser(bytes);
    const decOuter = dec.value!OuterStructWithPointerToStruct;

    //can't compare the two structs directly since the pointers
    //won't match but the values will.
    checkEqual(decOuter.s, outer.s);
    checkEqual(*decOuter.inner, *outer.inner);
    checkNotEqual(decOuter.inner, outer.inner); //ptrs shouldn't match
    checkEqual(decOuter.b, outer.b);

    checkThrown!RangeError(dec.value!ubyte); //no bytes
}


private class InnerClass {
    ushort s;
    ubyte b;
    this() {} //needed for decerealisation
    this(ushort s, ubyte b) { this.s = s; this.b = b; }
    override string toString() const { //so it can be used in checkEqual
        import std.conv;
        return text("InnerClass(", s, ", ", b);
    }

}

private struct OuterStructWithClass {
    ushort s;
    InnerClass inner;
    ubyte b;
}

void testStructWithClassReference() {
    auto enc = Cerealiser();
    auto outer = OuterStructWithClass(2, new InnerClass(3, 5), 8);
    enc ~= outer;

    const bytes = [ 0, 2, 0, 3, 5, 8];
    checkEqual(enc.bytes, bytes);

    auto dec = Decerealiser(bytes);
    const decOuter = dec.value!OuterStructWithClass;

    //can't compare the two structs directly since the pointers
    //won't match but the values will.
    checkEqual(decOuter.s, outer.s);
    checkEqual(decOuter.inner, outer.inner);
    checkNotEqual(decOuter.inner, outer.inner); //ptrs shouldn't match
    checkEqual(decOuter.b, outer.b);
}

void testPointerToInt() {
    auto enc = Cerealiser();
    auto i = new int; *i = 4;
    enc ~= i;
    const bytes = [0, 0, 0, 4];
    checkEqual(enc.bytes, bytes);

    auto dec = Decerealiser(bytes);
    checkEqual(*dec.value!(int*), *i);
}
