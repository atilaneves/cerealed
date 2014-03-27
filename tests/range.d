module tests.range;

import unit_threaded;
import cerealed;
import std.range;
import core.exception;


void testInputRange() {
    auto enc = new OldCerealiser;
    enc ~= iota(cast(ubyte)5);
    checkEqual(enc.bytes, [0, 5, 0, 1, 2, 3, 4]);
}

private ubyte[] gOutputBytes;

private struct MyOutputRange {
    void put(in ubyte b) {
        gOutputBytes ~= b;
    }
}

void testMyOutputRange() {
    static assert(isOutputRange!(MyOutputRange, ubyte));
}

@SingleThreaded
void testOutputRangeValue() {
    gOutputBytes = [];

    auto dec = new OldDecerealiser([0, 5, 2, 3, 9, 6, 1]);
    auto output = dec.value!MyOutputRange;

    checkEqual(gOutputBytes, [2, 3, 9, 6, 1]);
}

@SingleThreaded
void testOutputRangeRead() {
    gOutputBytes = [];

    auto dec = new OldDecerealiser([0, 5, 2, 3, 9, 6, 1]);
    auto output = MyOutputRange();
    dec.read(output);

    checkEqual(gOutputBytes, [2, 3, 9, 6, 1]);
}


private ubyte[] gInputBytes;

private struct MyInputRange {
    this(ubyte[] bytes) { gInputBytes = bytes; }
    ubyte front() { return gInputBytes.front; }
    void popFront() { gInputBytes.popFront; }
    bool empty() { return gInputBytes.empty(); }
    @property ulong length() { return gInputBytes.length; }
    static assert(isInputRange!MyInputRange);
}

private struct StructWithInputRange {
    ubyte b;
    MyInputRange input;
}

@SingleThreaded
void testEmbeddedInputRange() {
    auto enc = new OldCerealiser;
    auto str = StructWithInputRange(2, MyInputRange([9, 7, 6]));
    enc ~= str;
    const bytes = [2, 0, 3, 9, 7, 6];
    checkEqual(enc.bytes, bytes);

    //no deserialisation for InputRange
    auto dec = new OldDecerealiser(bytes);
    checkThrown!AssertError(dec.value!StructWithInputRange);
}

private struct StructWithOutputRange {
    ubyte b1;
    MyOutputRange output;
    ubyte b2;
}

@SingleThreaded
void testEmbeddedOutputRange() {
    auto enc = new OldCerealiser;
    checkThrown!AssertError(enc ~= StructWithOutputRange());
    auto dec = new OldDecerealiser([255, //1st byte
                                 0, 3, 9, 7, 6, //length, values
                                 12]); //2nd byte
    gOutputBytes = [];
    const str = dec.value!StructWithOutputRange;
    writelnUt("dec bytes is ", dec.bytes);
    checkThrown!RangeError(dec.value!ubyte); //no more bytes

    checkEqual(str.b1, 255);
    checkEqual(str.b2, 12);
    checkEqual(gOutputBytes, [9, 7, 6]);
}
