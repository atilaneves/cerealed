import unit_threaded.check;
import cerealed.cerealiser;
import cerealed.decerealiser;
import core.exception;

private class DummyClass {
    int i;
    bool opEquals(DummyClass d) const pure nothrow {
        return false;
    }
}

void testDummyClass() {
    auto enc = new Cerealiser();
    auto dummy = new DummyClass();
    enc ~= dummy;

    auto dec = new Decerealiser(enc.bytes);
}
