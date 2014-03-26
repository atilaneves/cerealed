module tests.range;

import unit_threaded;
import cerealed;
import std.range;


void testInputRange() {
    auto enc = new Cerealiser;
    enc ~= iota(cast(ubyte)5);
    checkEqual(enc.bytes, [0, 5, 0, 1, 2, 3, 4]);
}

private static ubyte[] gOutputBytes;

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

    auto dec = new Decerealiser([0, 5, 2, 3, 9, 6, 1]);
    auto output = dec.value!MyOutputRange;

    checkEqual(gOutputBytes, [2, 3, 9, 6, 1]);
}

@SingleThreaded
void testOutputRangeRead() {
    gOutputBytes = [];

    auto dec = new Decerealiser([0, 5, 2, 3, 9, 6, 1]);
    auto output = MyOutputRange();
    dec.read(output);

    checkEqual(gOutputBytes, [2, 3, 9, 6, 1]);
}
