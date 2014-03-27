module tests.encode;

import unit_threaded.check;
import cerealed.cerealiser;


void testEncodeBool() {
    auto cereal = Cerealiser();
    cereal.write(false);
    cereal.write(true);
    cereal.write(false);
    checkEqual(cereal.bytes, [ 0x0, 0x1, 0x0 ]);

    cereal ~= true;
    checkEqual(cereal.bytes, [ 0x0, 0x1, 0x0, 0x1 ]);
}

void testEncodeByte() {
    auto cereal = Cerealiser();
    byte[] ins = [ 1, 3, -2, 5, -4];
    foreach(i; ins) cereal.write(i);
    checkEqual(cereal.bytes, [ 0x1, 0x3, 0xfe, 0x5, 0xfc ]);
}

void testEncodeUByte() {
    auto cereal = Cerealiser();
    ubyte[] ins = [ 2, 3, 12, 10];
    foreach(i; ins) cereal ~= i;
    checkEqual(cereal.bytes, [ 0x2, 0x3, 0xc, 0xa ]);
}

void testEncodeShort() {
    auto cereal = Cerealiser();
    short[] ins = [ -2, 3, -32767, 0];
    foreach(i; ins) cereal ~= i;
    checkEqual(cereal.bytes, [ 0xff, 0xfe, 0x0, 0x3, 0x80, 0x01, 0x0, 0x0 ]);
}

void testEncodeUShort() {
    auto cereal = Cerealiser();
    ushort[] ins = [ 2, 3, cast(short)65535, 0];
    foreach(i; ins) cereal ~= i;
    checkEqual(cereal.bytes, [ 0x0, 0x2, 0x0, 0x3, 0xff, 0xff, 0x0, 0x0 ]);
}

void testEncodeInt() {
    auto cereal = new OldCerealiser();
    int[] ins = [ 3, -1_000_000];
    foreach(i; ins) cereal ~= i;
    checkEqual(cereal.bytes, [ 0x0, 0x0, 0x0, 0x3, 0xff, 0xf0, 0xbd, 0xc0 ]);
}

void testEncodeUInt() {
    auto cereal = new OldCerealiser();
    uint[] ins = [ 1_000_000, 0];
    foreach(i; ins) cereal ~= i;
    checkEqual(cereal.bytes, [ 0x0, 0x0f, 0x42, 0x40, 0x0, 0x0, 0x0, 0x0 ]);
}

void testEncodeLong() {
    auto cereal = new OldCerealiser();
    long[] ins = [1, 2];
    foreach(i; ins) cereal ~= i;
    checkEqual(cereal.bytes, [ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2]);
}

void testEncodeULong() {
    auto cereal = new OldCerealiser();
    cereal ~= 45L;
    checkEqual(cereal.bytes, [ 0, 0, 0, 0, 0, 0, 0, 45 ]);
    cereal = new OldCerealiser();
    cereal ~= 42L;
    checkEqual(cereal.bytes, [ 0, 0, 0, 0, 0, 0, 0, 42 ]);
}

void testEncodeFloat() {
    auto cereal = new OldCerealiser();
    cereal ~= 1.0f;
}

void testEncodeDouble() {
    auto cereal = new OldCerealiser();
    cereal ~= 1.0;
}

void testEncodeChars() {
    auto cereal = new OldCerealiser();
    char  c; cereal ~= c;
    wchar w; cereal ~= w;
    dchar d; cereal ~= d;
    checkEqual(cereal.bytes, [ 0xff, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff]);
}

void testEncodeArray() {
    auto cereal = new OldCerealiser();
    const ints = [ 2, 6, 9];
    cereal ~= ints;
    //encoding should be a short with the length, plus payload
    checkEqual(cereal.bytes, [ 0, 3, 0, 0, 0, 2, 0, 0, 0, 6, 0, 0, 0, 9]);
}

void testEncodeAssocArray() {
    auto cereal = new OldCerealiser();
    const intToInt = [ 1:2, 3:6];
    cereal ~= intToInt;
    //short with length, then payload
    checkEqual(cereal.bytes, [ 0, 2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 6]);
}

void testEncodeString() {
    auto cereal = new OldCerealiser();
    const str = "foobarbaz";
    cereal ~= str;
    //short with length, then payload
    checkEqual(cereal.bytes, [ 0, 9, 'f', 'o', 'o', 'b', 'a', 'r', 'b', 'a', 'z' ]);
}

void testEncodeNibble() {
    auto cereal = new OldCerealiser();
    cereal.writeBits(0x4, 4);
    cereal.writeBits(0xf, 4);
    checkEqual(cereal.bytes, [ 0x4f ]);
}

void testEncodeSubByte() {
    auto cereal = new OldCerealiser();
    cereal.writeBits(1, 1);
    cereal.writeBits(3, 2);
    cereal.writeBits(0, 1);
    cereal.writeBits(5, 3);
    cereal.writeBits(1, 1);
    checkEqual(cereal.bytes, [ 0xeb]);
}

void testEncodeSubWord() {
    auto cereal = new OldCerealiser();
    cereal.writeBits(4, 3);
    cereal.writeBits(7, 3);
    cereal.writeBits(23, 5);
    cereal.writeBits(1, 2);
    cereal.writeBits(2, 3);
    checkEqual(cereal.bytes, [ 0x9e, 0xea]);
}

void testEncodeMoreThan8Bits() {
    {
        auto cereal = new OldCerealiser();
        cereal.writeBits(1, 9);
        cereal.writeBits(15, 7);
        checkEqual(cereal.bytes, [ 0x00, 0x8f]);
    }
    {
        auto cereal = new OldCerealiser();
        cereal.writeBits((0x9e << 1) | 1, 9);
        cereal.writeBits(0xea & 0x7f, 7);
        checkEqual(cereal.bytes, [ 0x9e, 0xea]);
    }
}

void testEncodeFailsIfTooBigForBits() {
    auto cereal = new OldCerealiser();
    checkNotThrown(cereal.writeBits(1, 1));
    checkThrown(cereal.writeBits(2, 1));
    checkNotThrown(cereal.writeBits(3, 2));
    checkThrown(cereal.writeBits(5, 2));
}

void testEncodeTwoBytesBits() {
    auto cereal = new OldCerealiser();
    immutable uint value = 5;
    cereal.writeBits(3, 4);
    cereal.writeBits(1, 1);
    cereal.writeBits(2, 2);
    cereal.writeBits(0, 1);
    cereal.writeBits(5, 8);
    checkEqual(cereal.bytes, [0x3c, 0x05]);
}
