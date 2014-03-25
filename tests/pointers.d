module tests.pointers;

import unit_threaded;
import cerealed;
import core.exception;


private struct InnerStruct {
    ubyte b;
    ushort s;
}

private struct OuterStruct {
    ushort s;
    InnerStruct* inner;
    ubyte b;
}

void testPointerToStruct() {
    auto enc = new Cerealiser;
    //outer not const because not copyable from const
    auto outer = OuterStruct(3, new InnerStruct(7, 2), 5);
    enc ~= outer;

    const bytes = [ 0, 3, 7, 0, 2, 5];
    checkEqual(enc.bytes, bytes);

    auto dec = new Decerealiser(bytes);
    const decOuter = dec.value!OuterStruct;

    //can't compare the two structs directly since the pointers
    //won't match but the values will.
    checkEqual(decOuter.s, outer.s);
    checkEqual(*decOuter.inner, *outer.inner);
    checkNotEqual(decOuter.inner, outer.inner); //ptrs shouldn't match
    checkEqual(decOuter.b, outer.b);

    checkThrown!RangeError(dec.value!ubyte); //no bytes
}
