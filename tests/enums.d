module tests.enums;

import unit_threaded;
import cerealed;
import core.exception;


private enum MyEnum { Foo, Bar, Baz };

void testEnum() {
    auto enc = Cerealiser();
    enc ~= MyEnum.Bar;
    enc ~= MyEnum.Baz;
    enc ~= MyEnum.Foo;
    checkEqual(enc.bytes,  [0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 0]);

    auto dec = new Decerealizer(enc.bytes);
    checkEqual(dec.value!MyEnum, MyEnum.Bar);
    checkEqual(dec.value!MyEnum, MyEnum.Baz);
    checkEqual(dec.value!MyEnum, MyEnum.Foo);
    checkThrown!RangeError(dec.value!ubyte);
}

void testDecodeEnum() {
    enum Foo : ubyte {
        Bar = 0,
        Baz = 1
    }

    auto cereal = Decerealiser([ 0, 1 ]);
    checkEqual(cereal.value!Foo, Foo.Bar);
    checkEqual(cereal.value!Foo, Foo.Baz);
    checkThrown!RangeError(cereal.value!ubyte);
}
