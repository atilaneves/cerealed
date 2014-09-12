module tests.decode;

import unit_threaded;
import cerealed.decerealiser;
import core.exception;

void testDecodeBool() {
    auto cereal = Decerealiser([1, 0, 1, 0, 0, 1]);
    bool val;
    cereal.grain(val); checkEqual(val, true);
    cereal.grain(val); checkEqual(val, false);
    cereal.grain(val); checkEqual(val, true);
    cereal.grain(val); checkEqual(val, false);
    cereal.grain(val); checkEqual(val, false);
    cereal.grain(val); checkEqual(val, true);
    cereal.value!bool.shouldThrow!RangeError; //no more bytes
}


void testDecodeByte() {
    auto cereal = Decerealiser([0x0, 0x2, 0xfc]);
    cereal.value!byte.shouldEqual(0);
    cereal.value!byte.shouldEqual(2);
    cereal.value!byte.shouldEqual(-4);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

void testDecodeRefByte() {
    auto cereal = Decerealiser([0xfc]);
    byte val;
    cereal.grain(val);
    val.shouldEqual(-4);
}

void testDecodeUByte() {
    auto cereal = Decerealiser([0x0, 0x2, 0xfc]);
    cereal.value!ubyte.shouldEqual(0);
    cereal.value!ubyte.shouldEqual(2);
    cereal.value!ubyte.shouldEqual(252);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

void testDecodeShort() {
    auto cereal = Decerealiser([0xff, 0xfe, 0x0, 0x3]);
    cereal.value!short.shouldEqual(-2);
    cereal.value!short.shouldEqual(3);
    checkThrown!RangeError(cereal.value!short); //no more bytes
}

void testDecodeRefShort() {
    auto cereal = Decerealiser([0xff, 0xfe]);
    short val;
    cereal.grain(val);
    val.shouldEqual(-2);
}

void testDecodeInt() {
    auto cereal = Decerealiser([ 0xff, 0xf0, 0xbd, 0xc0]);
    cereal.value!int.shouldEqual(-1_000_000);
    checkThrown!RangeError(cereal.value!int); //no more bytes
}

void testDecodeRefInt() {
    auto cereal = Decerealiser([0xff, 0xf0, 0xbd, 0xc0]);
    int val;
    cereal.grain(val);
    val.shouldEqual(-1_000_000);
}

void testDecodeLong() {
    auto cereal = Decerealiser([ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2]);
    cereal.value!long.shouldEqual(1);
    cereal.value!long.shouldEqual(2);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

void testDecodeRefLong() {
    auto cereal = Decerealiser([ 0, 0, 0, 0, 0, 0, 0, 1]);
    long val;
    cereal.grain(val);
    val.shouldEqual(1);
}

void testDecodeDouble() {
    auto cereal = Decerealiser([ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2]);
    checkNotThrown(cereal.value!double);
    checkNotThrown(cereal.value!double);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

void testDecodeChars() {
    auto cereal = Decerealiser([ 0xff, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff ]);
    cereal.value!char.shouldEqual(0xff);
    cereal.value!wchar.shouldEqual(0xffff);
    cereal.value!dchar.shouldEqual(0x0000ffff);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

void testDecodeRefChar() {
    auto cereal = Decerealiser([0xff]);
    char val;
    cereal.grain(val);
    val.shouldEqual(0xff);
}


void testDecodeArray() {
    auto cereal = Decerealiser([ 0, 3, 0, 0, 0, 2, 0, 0, 0, 6, 0, 0, 0, 9 ]);
    cereal.value!(int[]).shouldEqual([ 2, 6, 9 ]);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

void testDecodeRefArray() {
    auto cereal = Decerealiser([0, 1, 0, 0, 0, 2]);
    int[] val;
    cereal.grain(val);
    val.shouldEqual([2]);
}

void testDecodeArrayLongLength() {
    auto cereal = Decerealiser([ 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 2, 0, 0, 0, 6, 0, 0, 0, 9 ]);
    cereal.value!(int[], long).shouldEqual([ 2, 6, 9 ]);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

void testDecodeAssocArray() {
    auto cereal = Decerealiser([ 0, 2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 6 ]);
    cereal.value!(int[int]).shouldEqual([ 1:2, 3:6]);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}


void testDecodeRefAssocArray() {
    auto cereal = Decerealiser([0, 1, 0, 0, 0, 2, 0, 0, 0, 3]);
    int[int] val;
    cereal.grain(val);
    val.shouldEqual([2:3]);
}

void testDecodeAssocArrayIntLength() {
    auto cereal = Decerealiser([ 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 6 ]);
    cereal.value!(int[int], int).shouldEqual([ 1:2, 3:6]);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

void testDecodeString() {
    auto cereal = Decerealiser([0, 5, 'a', 't', 'o', 'y', 'n']);
    cereal.value!(string).shouldEqual("atoyn");
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

void testDecodeRefString() {
    auto cereal = Decerealiser([0, 5, 'a', 't', 'o', 'y', 'n']);
    string val;
    cereal.grain(val);
    val.shouldEqual("atoyn");
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

void testDecodeBits() {
    auto cereal = Decerealiser([ 0x9e, 0xea]);
    //1001 1110 1110 1010 or
    //100 111 10111 01 010
    cereal.readBits(3).shouldEqual(4);
    cereal.readBits(3).shouldEqual(7);
    cereal.readBits(5).shouldEqual(23);
    cereal.readBits(2).shouldEqual(1);
    cereal.readBits(3).shouldEqual(2);

    cereal.reset();
    cereal.readBits(3).shouldEqual(4);
    cereal.readBits(3).shouldEqual(7);
    cereal.readBits(5).shouldEqual(23);
    cereal.readBits(2).shouldEqual(1);
    cereal.readBits(3).shouldEqual(2);
}

void testDecodeBitsMultiByte() {
    auto cereal = Decerealiser([ 0x9e, 0xea]);
    cereal.readBits(9).shouldEqual(317);
    cereal.readBits(7).shouldEqual(0x6a);
}

void testDecodeStringArray() {
    auto dec = Decerealiser([ 0, 3,
                              0, 3, 'f', 'o', 'o',
                              0, 4, 'w', '0', '0', 't',
                              0, 2, 'l', 'i']);
    dec.value!(string[]).shouldEqual(["foo", "w00t", "li"]);
}
