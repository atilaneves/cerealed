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
    const bytes = [ 0, 3, 7, 0, 2, 5];
    auto enc = new Cerealiser;

    auto outer = OuterStruct(3, new InnerStruct(7, 2), 5);
    enc ~= outer;
    checkEqual(enc.bytes, bytes);
    checkEqual(enc.type(), Cereal.Type.Write);

    // auto dec = new Decerealiser;
    // checkEqual(dec.value!OuterStruct, outer);
    // checkThrown!RangeError(dec.value!ubyte); //no bytes
}
