import unit_threaded.check;
import cerealed.decerealiser;
import std.exception;
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
}

void testDecodeByte() {
    auto cereal = new Decerealiser([0x0, 0x2, 0xfc]);
    checkEqual(cereal.value!byte, 0);
    checkEqual(cereal.value!byte, 2);
    checkEqual(cereal.value!byte, -4);
    assertThrown!RangeError(cereal.value!byte);
}
