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


void testStaticArrayCerealiserWorks() {
    auto enc = StaticArrayCerealiser!WhateverStruct();
    enc ~= WhateverStruct(5, "blargh");
    checkEqual(enc.bytes, [ 0, 5, 0, 6, 'b', 'l', 'a', 'r', 'g', 'h' ]);
    checkThrown!RangeError(enc ~= cast(ubyte)3);
}

void testStaticArrayCerealiserFunction() {
    const(ubyte)[] bytes = cerealise(WhateverStruct(5, "blargh"));
    checkEqual(bytes, [ 0, 5, 0, 6, 'b', 'l', 'a', 'r', 'g', 'h' ]);
}
