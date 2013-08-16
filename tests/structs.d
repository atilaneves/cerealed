import unit_threaded.check;
import cerealed.cerealiser;
import cerealed.decerealiser;
import core.exception;


private struct DummyStruct {
//private:
    int i;
    double d;
    //string s;
}


void testDummyStruct() {
    auto enc = new Cerealiser();
    //auto dummy = DummyStruct(5, 6.0, "dummy!");
    auto dummy = DummyStruct(5, 6.0);
    enc ~= dummy;

    auto dec = new Decerealiser(enc.bytes);
    checkEqual(dec.value!DummyStruct, dummy);

    checkThrown!RangeError(dec.value!ubyte);
}
