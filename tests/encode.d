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
    short[] ins = [ -2, 3, -1, 0];
    foreach(i; ins) cereal ~= i;
    checkEqual(cereal.bytes, [ 0xfe, 0x3, 0xff, 0x0 ]);
}

void testEncodeUShort() {
    auto cereal = new Cerealiser();
    short[] ins = [ 2, 3, 1, 0];
    foreach(i; ins) cereal ~= i;
    checkEqual(cereal.bytes, [ 0x2, 0x3, 0x1, 0x0 ]);
}
