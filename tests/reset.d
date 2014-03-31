module tests.reset;

import unit_threaded;
import cerealed.cerealiser;
import cerealed.decerealiser;


void testResetCerealiser() {
    auto enc = Cerealiser();
    enc ~= 5;
    enc ~= 'a';
    checkEqual(enc.bytes, [0, 0, 0, 5, 'a']);
    const bytesSlice = enc.bytes;

    enc.reset();

    checkEqual(enc.bytes, []);
    checkEqual(bytesSlice, [0, 0, 0, 5, 'a']);

    enc ~= 2;
    checkEqual(enc.bytes, [0, 0, 0, 2]);
    checkEqual(bytesSlice, [0, 0, 0, 2, 'a']);
}


void testResetDecerealiser() {
    const ubyte[] bytes1 = [1, 2, 3, 5, 8, 13];
    auto dec = Decerealiser(bytes1);

    dec.value!int; //get rid of 4 bytes
    checkEqual(dec.bytes, [8, 13]);

    dec.value!short; //get rid of the remaining 2 bytes
    checkEqual(dec.bytes, []);

    dec.reset();
    checkEqual(dec.bytes, bytes1);

    const ubyte[] bytes2 = [3, 6, 9, 12];
    dec.reset(bytes2);
    checkEqual(dec.bytes, bytes2);
}


void testEmptyDecerealiser() {
    import core.exception: RangeError;
    auto dec = Decerealiser();
    checkThrown!RangeError(dec.value!ubyte); //no bytes
}
