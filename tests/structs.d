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


private struct ProtoHeaderStruct {
    this(ubyte i3, ubyte i1, ubyte i4, ubyte i8) {
        //TODO: eliminate need for this
        bits3 = i3;
        bits1 = i1;
        bits4 = i4;
        bits8 = i8;
    }
    Bits!3 bits3;
    Bits!1 bits1;
    Bits!4 bits4;
    ubyte bits8;
}

void testEncDecProtoHeaderStruct() {
    const hdr = ProtoHeaderStruct(6, 1, 3, 254);
    auto enc = new Cerealiser();
    enc ~= hdr; //1101 0011, 254
    checkEqual(enc.bytes, [0xd3, 254]);

    auto dec = new Decerealiser(enc.bytes);
    checkEqual(dec.value!ProtoHeaderStruct, hdr);
}
