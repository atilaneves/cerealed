import unit_threaded.check;
import cerealed.cerealiser;


void testEncodeBool() {
    auto cereal = new Cerealiser();
    cereal.write(false);
    cereal.write(true);
    cereal.write(false);
    checkEqual(cereal.bytes, [ 0x0, 0x1, 0x0 ]);

    cereal ~= true;
    checkEqual(cereal.bytes, [ 0x0, 0x1, 0x0, 0x1 ]);
}

void testEncodeByte() {
    auto cereal = new Cerealiser();
    byte[] ins = [ 1, 3, -2, 5, -4];
    foreach(i; ins) cereal.write(i);
    checkEqual(cereal.bytes, [ 0x1, 0x3, 0xfe, 0x5, 0xfc ]);
}

void testEncodeUByte() {
    auto cereal = new Cerealiser();
    ubyte[] ins = [ 2, 3, 12, 10];
    foreach(i; ins) cereal ~= i;
    checkEqual(cereal.bytes, [ 0x2, 0x3, 0xc, 0xa ]);
}

void testEncodeShort() {
    auto cereal = new Cerealiser();
    short[] ins = [ -2, 3, -32767, 0];
    foreach(i; ins) cereal ~= i;
    checkEqual(cereal.bytes, [ 0xff, 0xfe, 0x0, 0x3, 0x80, 0x01, 0x0, 0x0 ]);
}

void testEncodeUShort() {
    auto cereal = new Cerealiser();
    ushort[] ins = [ 2, 3, cast(short)65535, 0];
    foreach(i; ins) cereal ~= i;
    checkEqual(cereal.bytes, [ 0x0, 0x2, 0x0, 0x3, 0xff, 0xff, 0x0, 0x0 ]);
}

void testEncodeInt() {
    auto cereal = new Cerealiser();
    int[] ins = [ 3, -1_000_000];
    foreach(i; ins) cereal ~= i;
    checkEqual(cereal.bytes, [ 0x0, 0x0, 0x0, 0x3, 0xff, 0xf0, 0xbd, 0xc0 ]);
}

void testEncodeUInt() {
    auto cereal = new Cerealiser();
    uint[] ins = [ 1_000_000, 0];
    foreach(i; ins) cereal ~= i;
    checkEqual(cereal.bytes, [ 0x0, 0x0f, 0x42, 0x40, 0x0, 0x0, 0x0, 0x0 ]);
}

void testEncodeLong() {
    auto cereal = new Cerealiser();
    long[] ins = [1, 2];
    foreach(i; ins) cereal ~= i;
    checkEqual(cereal.bytes, [ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2]);
}

void testEncodeULong() {
    auto cereal = new Cerealiser();
    cereal ~= 45L;
    checkEqual(cereal.bytes, [ 0, 0, 0, 0, 0, 0, 0, 45 ]);
    cereal = new Cerealiser();
    cereal ~= 42L;
    checkEqual(cereal.bytes, [ 0, 0, 0, 0, 0, 0, 0, 42 ]);
}

void testEncodeFloat() {
    auto cereal = new Cerealiser();
    cereal ~= 1.0f;
}

void testEncodeDouble() {
    auto cereal = new Cerealiser();
    cereal ~= 1.0;
}

void testEncodeChars() {
    auto cereal = new Cerealiser();
    char  c; cereal ~= c;
    wchar w; cereal ~= w;
    dchar d; cereal ~= d;
    checkEqual(cereal.bytes, [ 0xff, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff]);
}

void testEncodeArray() {
    auto cereal = new Cerealiser();
    const ints = [ 2, 6, 9];
    cereal ~= ints;
    //encoding should be a short with the length, plus payload
    checkEqual(cereal.bytes, [ 0, 3, 0, 0, 0, 2, 0, 0, 0, 6, 0, 0, 0, 9]);
}

void testEncodeAssocArray() {
    auto cereal = new Cerealiser();
    const intToInt = [ 1:2, 3:6];
    cereal ~= intToInt;
    //short with length, then payload
    checkEqual(cereal.bytes, [ 0, 2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 6]);
}
