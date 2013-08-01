import unit_threaded.check;
import cerealed.decerealiser;

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

void tetDecodeByte() {
    auto cereal = new Decerealiser([0x0, 0x2, -0xfc]);
    byte val;
    cereal.grain(val); checkEqual(val, 0);
    cereal.grain(val); checkEqual(val, 2);
    cereal.grain(val); checkEqual(val, -4);
    // checkEqual(cereal.value!(byte)(), 0);
    // checkEqual(cereal.value!byte, 2);
    // checkEqual(cereal.value!byte, -4);
}
