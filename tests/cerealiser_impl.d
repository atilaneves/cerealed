module tests.cerealiser_impl;
import unit_threaded;
import cerealed;
import core.exception;


struct WhateverStruct {
    ushort i;
    string s;
}

@("old.cerealiser")
unittest {
    auto enc = DynamicArrayCerealiser();
    enc ~= WhateverStruct(5, "blargh");
    enc.bytes.shouldEqual([ 0, 5, 0, 6, 'b', 'l', 'a', 'r', 'g', 'h' ]);
    enc.reset();
    enc.bytes.length.shouldEqual(0);
    (enc ~= 4).shouldNotThrow!RangeError;
}

@("scope.buffer.cerealiser")
unittest {
    ubyte[32] buf = void;

    writelnUt("Creating the range");
    auto sbufRange = ScopeBufferRange(buf);

    scope(exit) sbufRange.free();

    writelnUt("Creating the cerealiser");
    auto enc = CerealiserImpl!ScopeBufferRange(sbufRange);

    enc ~= WhateverStruct(5, "blargh");
    enc.bytes.shouldEqual([ 0, 5, 0, 6, 'b', 'l', 'a', 'r', 'g', 'h' ]);
}


@("cerealise")
unittest {
   WhateverStruct(5, "blargh").cerealise!(bytes => bytes.shouldEqual([0, 5, 0, 6, 'b', 'l', 'a', 'r', 'g', 'h']));
}
