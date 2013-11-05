import unit_threaded.check;
import unit_threaded.io;
import cerealed.cerealiser;
import cerealed.decerealiser;
import cerealed.bits;
import core.exception;


private void implEncDec(T)(T[] values) {
    auto enc = new Cerealiser();
    import std.stdio;
    foreach(b; values) {
        writelnUt("Encoding ", b);
        enc ~= b;
    }
    auto dec = new Decerealiser(enc.bytes);
    writelnUt("Decoding ", values);
    foreach(b; values) checkEqual(dec.value!T, b);
    checkThrown!RangeError(dec.value!ubyte); //no more bytes
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
    implEncDecValues!(ulong, [ 5_000_000, 2, 5_000_000_000, 1 ]);
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
    auto enc = new Cerealiser();
    enc ~= c; enc ~= w; enc ~= d;
    auto dec = new Decerealiser(enc.bytes);
    checkEqual(dec.value!char, c);
    checkEqual(dec.value!wchar, w);
    checkEqual(dec.value!dchar, d);
    checkThrown!RangeError(dec.value!ubyte); //no more bytes
}

void testEncDecArray() {
    auto enc = new Cerealiser();
    const ints = [ 2, 6, 9];
    enc ~= ints;
    auto dec = new Decerealiser(enc.bytes);
    checkEqual(dec.value!(int[]), ints);
    checkThrown!RangeError(dec.value!ubyte); //no more bytes
}

void testEncDecAssocArray() {
    auto enc = new Cerealiser();
    const intToInts = [ 1:2, 3:6, 9:18];
    enc ~= intToInts;
    auto dec = new Decerealiser(enc.bytes);
    checkEqual(dec.value!(int[int]), intToInts);
    checkThrown!RangeError(dec.value!ubyte); //no more bytes
}

void testEncDecBitsGrain() {
    auto enc = new Cerealiser();
    auto enc1 = Bits!3(7);
    enc.grain(enc1);
    auto enc2 = Bits!5(1);
    enc.grain(enc2);
    checkEqual(enc.bytes, [0xe1]);

    auto dec = new Decerealiser(enc.bytes);
    auto dec1 = Bits!3(0);
    dec.grain(dec1);
    checkEqual(dec1.value, 7);
    auto dec2 = Bits!5(0);
    dec.grain(dec2);
    checkEqual(dec2.value, 1);
}
