module tests.cerealiser_impl;
import unit_threaded;
import cerealed;
import core.exception;


struct WhateverStruct {
    ushort i;
    string s;
}

void testOldCerealiser() {
    auto enc = DynamicArrayCerealiser();
    enc ~= WhateverStruct(5, "blargh");
    checkEqual(enc.bytes, [ 0, 5, 0, 6, 'b', 'l', 'a', 'r', 'g', 'h' ]);
    enc.reset();
    checkEqual(enc.bytes, []);
    checkNotThrown!RangeError(enc ~= 4);
}

void testScopeBufferCerealiser() {
    ubyte[6] buf = void;

    writelnUt("Creating the range");
    auto sbufRange = ScopeBufferRange(buf);

    scope(exit) sbufRange.free();

    writelnUt("Creating the cerealiser");
    auto enc = CerealiserImpl!ScopeBufferRange(sbufRange);

    enc ~= WhateverStruct(5, "blargh");
    checkEqual(enc.bytes, [ 0, 5, 0, 6, 'b', 'l', 'a', 'r', 'g', 'h' ]);
}
