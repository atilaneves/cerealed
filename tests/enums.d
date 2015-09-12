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
    enc.bytes.shouldEqual([0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 0]);

    auto dec = Decerealizer(enc.bytes);
    dec.value!MyEnum.shouldEqual(MyEnum.Bar);
    dec.value!MyEnum.shouldEqual(MyEnum.Baz);
    dec.value!MyEnum.shouldEqual(MyEnum.Foo);
    dec.value!ubyte.shouldThrow!RangeError;
}

void testDecodeEnum() {
    enum Foo : ubyte {
        Bar = 0,
        Baz = 1
    }

    auto cereal = Decerealiser([ 0, 1 ]);
    shouldEqual(cereal.value!Foo, Foo.Bar);
    shouldEqual(cereal.value!Foo, Foo.Baz);
    cereal.value!ubyte.shouldThrow!RangeError;
}
