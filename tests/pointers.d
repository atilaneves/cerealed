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

    auto dec = new Decerealiser(bytes);
    auto decOuter = OuterStruct();
    dec.grain(decOuter.s);
    checkEqual(decOuter.s, 3);
    dec.grainPointer(decOuter.inner);
    checkEqual(*decOuter.inner, InnerStruct(7, 2));
    dec.grain(decOuter.b);
    checkEqual(decOuter.b, 5);
    checkThrown!RangeError(dec.value!ubyte); //no bytes
}
