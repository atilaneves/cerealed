module tests.nested;

import unit_threaded;
import cerealed;

struct Nested {
    Nested[int] aa;
}

struct SomeStruct {
    string[] str;
    int[][] ints;
    Nested[] nesteds;
}

void testEmptyNested() {
    SomeStruct original, restored;
    auto enc = Cerealiser();
    enc ~= original;
    auto dec = Decerealiser(enc.bytes);
    restored = dec.value!(SomeStruct);

    original.shouldEqual(restored);
}


void testNested() {
    auto some = SomeStruct(["foo", "sunny"],
                           [[2, 4], [1, 3, 5]],
                           [Nested([7: Nested()])]);
    auto enc = Cerealiser();
    enc ~= some;
    enc.bytes.shouldEqual([0, 2, 0, 3, 'f', 'o', 'o', 0, 5, 's', 'u', 'n', 'n', 'y',
                           0, 2, 0, 2, 0, 0, 0, 2, 0, 0, 0, 4, 0, 3, 0, 0, 0, 1, 0, 0, 0, 3, 0, 0, 0, 5,
                           0, 1, 0, 1, 0, 0, 0, 7, 0, 0]);
    auto dec = Decerealiser(enc.bytes);
    dec.value!SomeStruct.shouldEqual(some);
}
