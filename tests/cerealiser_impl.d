module tests.cerealiser_impl;
import unit_threaded;
import cerealed;

struct WhateverStruct {
    ushort i;
    string s;
}

void testOldCerealiser() {
    auto enc = ArrayCerealiser();
    enc ~= WhateverStruct(5, "blargh");
    checkEqual(enc.bytes, [ 0, 5, 0, 6, 'b', 'l', 'a', 'r', 'g', 'h' ]);
    enc.reset();
    checkEqual(enc.bytes, []);
}
