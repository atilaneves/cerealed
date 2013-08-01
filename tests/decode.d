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
    checkThrown!RangeError(cereal.value!byte); //no more bytes
}

void testDecodeShort() {
    auto cereal = new Decerealiser([0xff, 0xfe, 0x0, 0x3]);
    checkEqual(cereal.value!short, -2);
    checkEqual(cereal.value!short, 3);
}

void testDecodeInt() {
    auto cereal = new Decerealiser([ 0xff, 0xf0, 0xbd, 0xc0]);
    checkEqual(cereal.value!int, -1_000_000);
}

void testDecodeLong() {
    auto cereal = new Decerealiser([ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2]);
    checkEqual(cereal.value!long, 1);
    checkEqual(cereal.value!long, 2);
}
