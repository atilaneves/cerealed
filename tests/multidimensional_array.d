module tests.multidimensional_array;

import unit_threaded;
import cerealed;


void testEmptyMultidimensionalArray() {
    int[][] original, restored;
    auto enc = Cerealiser();
    enc ~= original;
    auto dec = Decerealiser(enc.bytes);
    restored = dec.value!(int[][]);
    assert(original == restored);
}


void testMultidimensionalArray() {
    int[][] some = [
        [3, 5, 6],
        [-3, 6, int.max, int.min],
    ];
    auto enc = Cerealiser();
    enc ~= some;
    writelnUt(enc.bytes);
    enc.bytes.shouldEqual([
        0, 2,
            0, 3,
                0, 0, 0, 3,
                0, 0, 0, 5,
                0, 0, 0, 6,
            0, 4,
                255, 255, 255, 253,
                  0,   0,   0,   6,
                127, 255, 255, 255,
                128,   0,   0,   0
    ]);
    auto dec = Decerealiser(enc.bytes);
    assert(some == dec.value!(int[][]));
}
