module tests.reset;

import unit_threaded;
import cerealed.cerealiser;
import cerealed.decerealiser;


void testResetCerealiser() {
    auto enc = Cerealiser();
    enc ~= 5;
    enc ~= 'a';
    enc.bytes.shouldEqual([0, 0, 0, 5, 'a']);
    const bytesSlice = enc.bytes;

    enc.reset();

    enc.bytes.shouldEqual([]);
    bytesSlice.shouldEqual([0, 0, 0, 5, 'a']);

    enc ~= 2;
    enc.bytes.shouldEqual([0, 0, 0, 2]);
    bytesSlice.shouldEqual([0, 0, 0, 2, 'a']);
}


void testResetDecerealiser() {
    const ubyte[] bytes1 = [1, 2, 3, 5, 8, 13];
    auto dec = Decerealiser(bytes1);

    dec.value!int; //get rid of 4 bytes
    dec.bytes.shouldEqual([8, 13]);

    dec.value!short; //get rid of the remaining 2 bytes
    dec.bytes.shouldEqual([]);

    dec.reset();
    dec.bytes.shouldEqual(bytes1);

    const ubyte[] bytes2 = [3, 6, 9, 12];
    dec.reset(bytes2);
    dec.bytes.shouldEqual(bytes2);
}


void testEmptyDecerealiser() {
    import core.exception: RangeError;
    auto dec = Decerealiser();
    dec.value!ubyte.shouldThrow!RangeError; //no bytes
}
