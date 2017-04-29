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

void testEncDecBool() {
    implEncDec([ true, true, false, false, true]);
}


private void implEncDecValues(T, alias arr)() {
    T[] values = arr;
    implEncDec(values);
}

void testEncDecByte() {
    implEncDecValues!(byte, [ 1, 3, -2, 5, -4 ]);
}

void testEncDecUByte() {
    implEncDecValues!(ubyte, [ 1, 255, 12 ]);
}

void testEncDecShort() {
    implEncDecValues!(short, [ 1, -2, -32768, 5 ]);
}

void testEncDecUShort() {
    implEncDecValues!(short, [ 1, -2, 32767, 5 ]);
}

void testEncDecInt() {
    implEncDecValues!(int, [ 1, -2, -1_000_000, 2_000_000 ]);
}

void testEncDecUInt() {
   implEncDecValues!(uint, [ 1, -2, 1_000_000, 2_000_000 ]);
}

void testEncDecLong() {
    implEncDecValues!(long, [ 5_000_000, 2, -3, -5_000_000_000, 1 ]);
}

void testEncDecULong() {
    implEncDecValues!(ulong, [ 5_000_000, 2, 7_000_000_000, 1 ]);
}

void testEncDecFloat() {
    implEncDec([ 2.0f, -4.3f, 3.1415926f ]); //don't add a value without 'f'!
}

void testEncDecDouble() {
    implEncDec([ 2.0, -9.0 ]);
}

void testEncDecChars() {
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

void testEncDecArray() {
    auto enc = Cerealiser();
    const ints = [ 2, 6, 9];
    enc ~= ints;
    auto dec = Decerealiser(enc.bytes);
    dec.value!(int[]).shouldEqual(ints);
    dec.value!ubyte.shouldThrow!RangeError; //no more bytes
}


@("struct with @LengthType") unittest {
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

void testEncDecAssocArray() {
    auto enc = Cerealiser();
    const intToInts = [ 1:2, 3:6, 9:18];
    enc ~= intToInts;
    auto dec = Decerealiser(enc.bytes);
    dec.value!(int[int]).shouldEqual(intToInts);
    dec.value!ubyte.shouldThrow!RangeError; //no more bytes
}
