module tests.decode;

import unit_threaded.check;
import cerealed.decerealiser;
import core.exception;

void testDecodeBool() {
    auto cereal = new OldDecerealiser([1, 0, 1, 0, 0, 1]);
    bool val;
    cereal.grain(val); checkEqual(val, true);
    cereal.grain(val); checkEqual(val, false);
    cereal.grain(val); checkEqual(val, true);
    cereal.grain(val); checkEqual(val, false);
    cereal.grain(val); checkEqual(val, false);
    cereal.grain(val); checkEqual(val, true);
    checkThrown!RangeError(cereal.value!bool); //no more bytes
}


void testDecodeByte() {
    auto cereal = new OldDecerealiser([0x0, 0x2, 0xfc]);
    checkEqual(cereal.value!byte, 0);
    checkEqual(cereal.value!byte, 2);
    checkEqual(cereal.value!byte, -4);
    checkThrown!RangeError(cereal.value!byte); //no more bytes
}

void testDecodeRefByte() {
    auto cereal = new OldDecerealiser([0xfc]);
    byte val;
    cereal.grain(val);
    checkEqual(val, -4);
}

void testDecodeUByte() {
    auto cereal = new OldDecerealiser([0x0, 0x2, 0xfc]);
    checkEqual(cereal.value!ubyte, 0);
    checkEqual(cereal.value!ubyte, 2);
    checkEqual(cereal.value!ubyte, 252);
    checkThrown!RangeError(cereal.value!ubyte); //no more bytes
}

void testDecodeShort() {
    auto cereal = new OldDecerealiser([0xff, 0xfe, 0x0, 0x3]);
    checkEqual(cereal.value!short, -2);
    checkEqual(cereal.value!short, 3);
    checkThrown!RangeError(cereal.value!short); //no more bytes
}

void testDecodeRefShort() {
    auto cereal = new OldDecerealiser([0xff, 0xfe]);
    short val;
    cereal.grain(val);
    checkEqual(val, -2);
}

void testDecodeInt() {
    auto cereal = new OldDecerealiser([ 0xff, 0xf0, 0xbd, 0xc0]);
    checkEqual(cereal.value!int, -1_000_000);
    checkThrown!RangeError(cereal.value!int); //no more bytes
}

void testDecodeRefInt() {
    auto cereal = new OldDecerealiser([0xff, 0xf0, 0xbd, 0xc0]);
    int val;
    cereal.grain(val);
    checkEqual(val, -1_000_000);
}

void testDecodeLong() {
    auto cereal = new OldDecerealiser([ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2]);
    checkEqual(cereal.value!long, 1);
    checkEqual(cereal.value!long, 2);
    checkThrown!RangeError(cereal.value!byte); //no more bytes
}

void testDecodeRefLong() {
    auto cereal = new OldDecerealiser([ 0, 0, 0, 0, 0, 0, 0, 1]);
    long val;
    cereal.grain(val);
    checkEqual(val, 1);
}

void testDecodeDouble() {
    auto cereal = new OldDecerealiser([ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2]);
    checkNotThrown(cereal.value!double);
    checkNotThrown(cereal.value!double);
    checkThrown!RangeError(cereal.value!ubyte); //no more bytes
}

void testDecodeChars() {
    auto cereal = new OldDecerealiser([ 0xff, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff ]);
    checkEqual(cereal.value!char, 0xff);
    checkEqual(cereal.value!wchar, 0xffff);
    checkEqual(cereal.value!dchar, 0x0000ffff);
    checkThrown!RangeError(cereal.value!ubyte); //no more bytes
}

void testDecodeRefChar() {
    auto cereal = new OldDecerealiser([0xff]);
    char val;
    cereal.grain(val);
    checkEqual(val, 0xff);
}


void testDecodeArray() {
    auto cereal = new OldDecerealiser([ 0, 3, 0, 0, 0, 2, 0, 0, 0, 6, 0, 0, 0, 9 ]);
    checkEqual(cereal.value!(int[]), [ 2, 6, 9 ]);
    checkThrown!RangeError(cereal.value!ubyte); //no more bytes
}

void testDecodeRefArray() {
    auto cereal = new OldDecerealiser([0, 1, 0, 0, 0, 2]);
    int[] val;
    cereal.grain(val);
    checkEqual(val, [2]);
}

void testDecodeArrayLongLength() {
    auto cereal = new OldDecerealiser([ 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 2, 0, 0, 0, 6, 0, 0, 0, 9 ]);
    checkEqual(cereal.value!(int[], long), [ 2, 6, 9 ]);
    checkThrown!RangeError(cereal.value!ubyte); //no more bytes
}

void testDecodeAssocArray() {
    auto cereal = new OldDecerealiser([ 0, 2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 6 ]);
    checkEqual(cereal.value!(int[int]), [ 1:2, 3:6]);
    checkThrown!RangeError(cereal.value!ubyte); //no more bytes
}


void testDecodeRefAssocArray() {
    auto cereal = new OldDecerealiser([0, 1, 0, 0, 0, 2, 0, 0, 0, 3]);
    int[int] val;
    cereal.grain(val);
    checkEqual(val, [2:3]);
}

void testDecodeAssocArrayIntLength() {
    auto cereal = new OldDecerealiser([ 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 6 ]);
    checkEqual(cereal.value!(int[int], int), [ 1:2, 3:6]);
    checkThrown!RangeError(cereal.value!ubyte); //no more bytes
}

void testDecodeString() {
    auto cereal = new OldDecerealiser([0, 5, 'a', 't', 'o', 'y', 'n']);
    checkEqual(cereal.value!(string), "atoyn");
    checkThrown!RangeError(cereal.value!ubyte); //no more bytes
}

void testDecodeRefString() {
    auto cereal = new OldDecerealiser([0, 5, 'a', 't', 'o', 'y', 'n']);
    string val;
    cereal.grain(val);
    checkEqual(val, "atoyn");
    checkThrown!RangeError(cereal.value!ubyte); //no more bytes
}

void testDecodeBits() {
    auto cereal = new OldDecerealiser([ 0x9e, 0xea]);
    //1001 1110 1110 1010 or
    //100 111 10111 01 010
    checkEqual(cereal.readBits(3), 4);
    checkEqual(cereal.readBits(3), 7);
    checkEqual(cereal.readBits(5), 23);
    checkEqual(cereal.readBits(2), 1);
    checkEqual(cereal.readBits(3), 2);

    cereal.reset();
    checkEqual(cereal.readBits(3), 4);
    checkEqual(cereal.readBits(3), 7);
    checkEqual(cereal.readBits(5), 23);
    checkEqual(cereal.readBits(2), 1);
    checkEqual(cereal.readBits(3), 2);
}

void testDecodeBitsMultiByte() {
    auto cereal = new OldDecerealiser([ 0x9e, 0xea]);
    checkEqual(cereal.readBits(9), 317);
    checkEqual(cereal.readBits(7), 0x6a);
}
