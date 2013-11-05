import unit_threaded.check;
import cerealed.cerealiser;
import cerealed.decerealiser;
import core.exception;


private struct DummyStruct {
    int i;
    double d;
    int[] a;
    bool b;
    double[int] aa;
    string s;

    void foo() {}
}


void testDummyStruct() {
    auto enc = new Cerealiser();
    auto dummy = DummyStruct(5, 6.0, [2, 3], true, [2: 4.0], "dummy!");
    enc ~= dummy;

    auto dec = new Decerealiser(enc.bytes);
    checkEqual(dec.value!DummyStruct, dummy);

    checkThrown!RangeError(dec.value!ubyte);
}

private struct StringStruct {
    string s;
}

void testDecodeStringStruct() {
    auto dec = new Decerealiser([0, 3, 'f', 'o', 'o']);
    auto str = StringStruct();
    dec.grain(str);
    checkEqual(str.s, "foo");
    checkThrown!RangeError(dec.value!ubyte);
}

void testEncodeStringStruct() {
    auto enc = new Cerealiser();
    const str = StringStruct("foo");
    enc ~= str;
    checkEqual(enc.bytes, [ 0, 3, 'f', 'o', 'o']);
}
