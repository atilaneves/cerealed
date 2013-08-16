import unit_threaded.check;
import cerealed.cerealiser;
import cerealed.decerealiser;
import core.exception;


private struct DummyStruct {
//private:
    int i;
    double d;
    int[] a;
    double[int] aa;
    //string s;
}


void testDummyStruct() {
    auto enc = new Cerealiser();
    //auto dummy = DummyStruct(5, 6.0, "dummy!");
    auto dummy = DummyStruct(5, 6.0, [2, 3], [2: 4.0]);
    enc ~= dummy;

    auto dec = new Decerealiser(enc.bytes);
    checkEqual(dec.value!DummyStruct, dummy);

    checkThrown!RangeError(dec.value!ubyte);
}
