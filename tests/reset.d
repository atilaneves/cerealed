module tests.reset;

import unit_threaded;
import cerealed.cerealiser;


void testResetCerealiser() {
    auto enc = new Cerealiser;
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
