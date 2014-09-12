module tests.encode;

import unit_threaded;
import cerealed.cerealiser;


void testEncodeBool() {
    auto cereal = Cerealiser();
    cereal.write(false);
    cereal.write(true);
    cereal.write(false);
    cereal.bytes.shouldEqual([ 0x0, 0x1, 0x0 ]);

    cereal ~= true;
    cereal.bytes.shouldEqual([ 0x0, 0x1, 0x0, 0x1 ]);
}

void testEncodeByte() {
    auto cereal = Cerealiser();
    byte[] ins = [ 1, 3, -2, 5, -4];
    foreach(i; ins) cereal.write(i);
    cereal.bytes.shouldEqual([ 0x1, 0x3, 0xfe, 0x5, 0xfc ]);
}

void testEncodeUByte() {
    auto cereal = Cerealiser();
    ubyte[] ins = [ 2, 3, 12, 10];
    foreach(i; ins) cereal ~= i;
    cereal.bytes.shouldEqual([ 0x2, 0x3, 0xc, 0xa ]);
}

void testEncodeShort() {
    auto cereal = Cerealiser();
    short[] ins = [ -2, 3, -32767, 0];
    foreach(i; ins) cereal ~= i;
    cereal.bytes.shouldEqual([ 0xff, 0xfe, 0x0, 0x3, 0x80, 0x01, 0x0, 0x0 ]);
}

void testEncodeUShort() {
    auto cereal = Cerealiser();
    ushort[] ins = [ 2, 3, cast(short)65535, 0];
    foreach(i; ins) cereal ~= i;
    cereal.bytes.shouldEqual([ 0x0, 0x2, 0x0, 0x3, 0xff, 0xff, 0x0, 0x0 ]);
}

void testEncodeInt() {
    auto cereal = Cerealiser();
    int[] ins = [ 3, -1_000_000];
    foreach(i; ins) cereal ~= i;
    cereal.bytes.shouldEqual([ 0x0, 0x0, 0x0, 0x3, 0xff, 0xf0, 0xbd, 0xc0 ]);
}

void testEncodeUInt() {
    auto cereal = Cerealiser();
    uint[] ins = [ 1_000_000, 0];
    foreach(i; ins) cereal ~= i;
    cereal.bytes.shouldEqual([ 0x0, 0x0f, 0x42, 0x40, 0x0, 0x0, 0x0, 0x0 ]);
}

void testEncodeLong() {
    auto cereal = Cerealiser();
    long[] ins = [1, 2];
    foreach(i; ins) cereal ~= i;
    cereal.bytes.shouldEqual([ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2]);
}

void testEncodeULong() {
    auto cereal = Cerealiser();
    cereal ~= 45L;
    cereal.bytes.shouldEqual([ 0, 0, 0, 0, 0, 0, 0, 45 ]);
    cereal = Cerealiser();
    cereal ~= 42L;
    cereal.bytes.shouldEqual([ 0, 0, 0, 0, 0, 0, 0, 42 ]);
}

void testEncodeFloat() {
    auto cereal = Cerealiser();
    cereal ~= 1.0f;
}

void testEncodeDouble() {
    auto cereal = Cerealiser();
    cereal ~= 1.0;
}

void testEncodeChars() {
    auto cereal = Cerealiser();
    char  c; cereal ~= c;
    wchar w; cereal ~= w;
    dchar d; cereal ~= d;
    cereal.bytes.shouldEqual([ 0xff, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff]);
}

void testEncodeArray() {
    auto cereal = Cerealiser();
    const ints = [ 2, 6, 9];
    cereal ~= ints;
    //encoding should be a short with the length, plus payload
    cereal.bytes.shouldEqual([ 0, 3, 0, 0, 0, 2, 0, 0, 0, 6, 0, 0, 0, 9]);
}

void testEncodeAssocArray() {
    auto cereal = Cerealiser();
    const intToInt = [ 1:2, 3:6];
    import std.traits;
    import std.range;
    cereal ~= intToInt;
    //short with length, then payload
    cereal.bytes.shouldEqual([ 0, 2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 6]);
}

void testEncodeString() {
    auto cereal = Cerealiser();
    const str = "foobarbaz";
    cereal ~= str;
    //short with length, then payload
    cereal.bytes.shouldEqual([ 0, 9, 'f', 'o', 'o', 'b', 'a', 'r', 'b', 'a', 'z' ]);
}

void testEncodeNibble() {
    auto cereal = Cerealiser();
    cereal.writeBits(0x4, 4);
    cereal.writeBits(0xf, 4);
    cereal.bytes.shouldEqual([ 0x4f ]);
}

void testEncodeSubByte() {
    auto cereal = Cerealiser();
    cereal.writeBits(1, 1);
    cereal.writeBits(3, 2);
    cereal.writeBits(0, 1);
    cereal.writeBits(5, 3);
    cereal.writeBits(1, 1);
    cereal.bytes.shouldEqual([ 0xeb]);
}

void testEncodeSubWord() {
    auto cereal = Cerealiser();
    cereal.writeBits(4, 3);
    cereal.writeBits(7, 3);
    cereal.writeBits(23, 5);
    cereal.writeBits(1, 2);
    cereal.writeBits(2, 3);
    cereal.bytes.shouldEqual([ 0x9e, 0xea]);
}

void testEncodeMoreThan8Bits() {
    {
        auto cereal = Cerealiser();
        cereal.writeBits(1, 9);
        cereal.writeBits(15, 7);
        cereal.bytes.shouldEqual([ 0x00, 0x8f]);
    }
    {
        auto cereal = Cerealiser();
        cereal.writeBits((0x9e << 1) | 1, 9);
        cereal.writeBits(0xea & 0x7f, 7);
        cereal.bytes.shouldEqual([ 0x9e, 0xea]);
    }
}

void testEncodeFailsIfTooBigForBits() {
    auto cereal = Cerealiser();
    checkNotThrown(cereal.writeBits(1, 1));
    checkThrown(cereal.writeBits(2, 1));
    checkNotThrown(cereal.writeBits(3, 2));
    checkThrown(cereal.writeBits(5, 2));
}

void testEncodeTwoBytesBits() {
    auto cereal = Cerealiser();
    immutable uint value = 5;
    cereal.writeBits(3, 4);
    cereal.writeBits(1, 1);
    cereal.writeBits(2, 2);
    cereal.writeBits(0, 1);
    cereal.writeBits(5, 8);
    cereal.bytes.shouldEqual([0x3c, 0x05]);
}
