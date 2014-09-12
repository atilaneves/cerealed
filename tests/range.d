module tests.range;

import unit_threaded;
import cerealed;
import std.range;
import core.exception;


void testInputRange() {
    auto enc = Cerealiser();
    enc ~= iota(cast(ubyte)5);
    enc.bytes.shouldEqual([0, 5, 0, 1, 2, 3, 4]);
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

    auto dec = Decerealiser([0, 5, 2, 3, 9, 6, 1]);
    auto output = dec.value!MyOutputRange;

    gOutputBytes.shouldEqual([2, 3, 9, 6, 1]);
}

@SingleThreaded
void testOutputRangeRead() {
    gOutputBytes = [];

    auto dec = Decerealiser([0, 5, 2, 3, 9, 6, 1]);
    auto output = MyOutputRange();
    dec.read(output);

    gOutputBytes.shouldEqual([2, 3, 9, 6, 1]);
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
    auto enc = Cerealiser();
    auto str = StructWithInputRange(2, MyInputRange([9, 7, 6]));
    enc ~= str;
    const bytes = [2, 0, 3, 9, 7, 6];
    enc.bytes.shouldEqual(bytes);

    //no deserialisation for InputRange
    auto dec = Decerealiser(bytes);
    enum compiles = __traits(compiles, { dec.value!StructWithInputRange; });
    static assert(!compiles, "Should not be able to read into an InputRange");
}

private struct StructWithOutputRange {
    ubyte b1;
    MyOutputRange output;
    ubyte b2;
}

@SingleThreaded
void testEmbeddedOutputRange() {
    auto enc = Cerealiser();
    enum compiles = __traits(compiles, { enc ~= StructWithOutputRange(); });
    static assert(!compiles, "Should not be able to read from an OutputRange");
    gOutputBytes = [];
    auto dec = Decerealiser([255, //1st byte
                             0, 3, 9, 7, 6, //length, values
                             12]); //2nd byte
    dec.bytes.shouldEqual([255, 0, 3, 9, 7, 6, 12]);
    const str = dec.value!StructWithOutputRange;
    writelnUt("dec bytes is ", dec.bytes);
    dec.value!ubyte.shouldThrow!RangeError; //no more bytes

    str.b1.shouldEqual(255);
    str.b2.shouldEqual(12);
    gOutputBytes.shouldEqual([9, 7, 6]);
}
