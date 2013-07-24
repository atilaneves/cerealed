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
    import std.stdio;
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
