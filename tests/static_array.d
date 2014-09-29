module tests.static_array;

import unit_threaded;
import cerealed;

void testStaticArray() {
    int[2] original, restored;

    original[0] = 34;
    original[1] = 45;
    auto enc = Cerealiser();
    enc ~= original;
    assert(enc.bytes == [
    // no length because it's already known
        0, 0, 0, 34,
        0, 0, 0, 45,
    ]);
    auto dec = Decerealiser(enc.bytes);
    restored = dec.value!(int[2]);

    assert(original == restored);
}
