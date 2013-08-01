import unit_threaded.check;
import cerealed.decerealiser;
import core.exception;

void testDecodeBool() {
    auto cereal = new Decerealiser([1, 0, 1, 0, 0, 1]);
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
    auto cereal = new Decerealiser([0x0, 0x2, 0xfc]);
    checkEqual(cereal.value!byte, 0);
    checkEqual(cereal.value!byte, 2);
    checkEqual(cereal.value!byte, -4);
    checkThrown!RangeError(cereal.value!byte); //no more bytes
}

void testDecodeUByte() {
    auto cereal = new Decerealiser([0x0, 0x2, 0xfc]);
    checkEqual(cereal.value!ubyte, 0);
    checkEqual(cereal.value!ubyte, 2);
    checkEqual(cereal.value!ubyte, 252);
    checkThrown!RangeError(cereal.value!ubyte); //no more bytes
}

void testDecodeShort() {
    auto cereal = new Decerealiser([0xff, 0xfe, 0x0, 0x3]);
    checkEqual(cereal.value!short, -2);
    checkEqual(cereal.value!short, 3);
    checkThrown!RangeError(cereal.value!short); //no more bytes
}

void testDecodeInt() {
    auto cereal = new Decerealiser([ 0xff, 0xf0, 0xbd, 0xc0]);
    checkEqual(cereal.value!int, -1_000_000);
    checkThrown!RangeError(cereal.value!int); //no more bytes
}

void testDecodeLong() {
    auto cereal = new Decerealiser([ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2]);
    checkEqual(cereal.value!long, 1);
    checkEqual(cereal.value!long, 2);
    checkThrown!RangeError(cereal.value!byte); //no more bytes
}

void testDecodeDouble() {
    auto cereal = new Decerealiser([ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2]);
    checkNotThrown(cereal.value!double);
    checkNotThrown(cereal.value!double);
    checkThrown!RangeError(cereal.value!ubyte); //no more bytes
}

void testDecodeChars() {
    auto cereal = new Decerealiser([ 0xff, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff ]);
    checkEqual(cereal.value!char, 0xff);
    checkEqual(cereal.value!wchar, 0xffff);
    checkEqual(cereal.value!dchar, 0x0000ffff);
    checkThrown!RangeError(cereal.value!ubyte); //no more bytes
}

void testDecodeAssocArray() {
    auto cereal = new Decerealiser([ 0, 2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 6 ]);
    checkEqual(cereal.value!(int[int]), [ 1:2, 3:6]);
}
