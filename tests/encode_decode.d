module tests.encode_decode;

import unit_threaded;
import cerealed.cerealiser;
import cerealed.decerealiser;
import core.exception;


private void implEncDec(T)(T[] values) {
    auto enc = Cerealiser();
    import std.stdio;
    foreach(b; values) {
        writelnUt("Encoding ", b);
        enc ~= b;
    }
    auto dec = Decerealiser(enc.bytes);
    writelnUt("Decoding to match ", values);
    writelnUt("Bytes: ", enc.bytes);
    foreach(b; values) shouldEqual(dec.value!T, b);
    dec.value!ubyte.shouldThrow!RangeError; //no more bytes
}

@("enc.dec.bool")
unittest {
    implEncDec([ true, true, false, false, true]);
}


private void implEncDecValues(T, alias arr)() {
    T[] values = arr;
    implEncDec(values);
}

@("enc.dec.byte")
unittest {
    implEncDecValues!(byte, [ 1, 3, -2, 5, -4 ]);
}

@("enc.dec.u.byte")
unittest {
    implEncDecValues!(ubyte, [ 1, 255, 12 ]);
}

@("enc.dec.short")
unittest {
    implEncDecValues!(short, [ 1, -2, -32768, 5 ]);
}

@("enc.dec.u.short")
unittest {
    implEncDecValues!(short, [ 1, -2, 32767, 5 ]);
}

@("enc.dec.int")
unittest {
    implEncDecValues!(int, [ 1, -2, -1_000_000, 2_000_000 ]);
}

@("enc.dec.u.int")
unittest {
   implEncDecValues!(uint, [ 1, -2, 1_000_000, 2_000_000 ]);
}

@("enc.dec.long")
unittest {
    implEncDecValues!(long, [ 5_000_000, 2, -3, -5_000_000_000, 1 ]);
}

@("enc.dec.u.long")
unittest {
    implEncDecValues!(ulong, [ 5_000_000, 2, 7_000_000_000, 1 ]);
}

@("enc.dec.float")
unittest {
    implEncDec([ 2.0f, -4.3f, 3.1415926f ]); //don't add a value without 'f'!
}

@("enc.dec.double")
unittest {
    implEncDec([ 2.0, -9.0 ]);
}

@("enc.dec.chars")
unittest {
    char c = 5;
    wchar w = 300;
    dchar d = 1_000_000;
    auto enc = Cerealiser();
    enc ~= c; enc ~= w; enc ~= d;
    auto dec = Decerealiser(enc.bytes);
    dec.value!char.shouldEqual(c);
    dec.value!wchar.shouldEqual(w);
    dec.value!dchar.shouldEqual(d);
    dec.value!ubyte.shouldThrow!RangeError; //no more bytes
}

@("enc.dec.array")
unittest {
    auto enc = Cerealiser();
    const ints = [ 2, 6, 9];
    enc ~= ints;
    auto dec = Decerealiser(enc.bytes);
    dec.value!(int[]).shouldEqual(ints);
    dec.value!ubyte.shouldThrow!RangeError; //no more bytes
}


@("struct with @LengthType")
unittest {
    import cerealed.attrs: LengthType;
    struct Foo {
        @LengthType!ubyte ushort[] arr;
    }

    auto enc = Cerealiser();
    auto foo = Foo([7, 8, 9]);
    enc ~= foo;
    enc.bytes.shouldEqual([3, 0, 7, 0, 8, 0, 9]);
    auto dec = Decerealiser(enc.bytes);
    dec.value!Foo.shouldEqual(foo);
}

@("enc.dec.assoc.array")
unittest {
    auto enc = Cerealiser();
    const intToInts = [ 1:2, 3:6, 9:18];
    enc ~= intToInts;
    auto dec = Decerealiser(enc.bytes);
    dec.value!(int[int]).shouldEqual(intToInts);
    dec.value!ubyte.shouldThrow!RangeError; //no more bytes
}
