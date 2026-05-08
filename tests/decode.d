module tests.decode;

import unit_threaded;
import cerealed.decerealiser;
import core.exception;

@("decode.bool")
unittest {
    import cerealed.cereal: grain;
    auto cereal = Decerealiser([1, 0, 1, 0, 0, 1]);
    bool val;
    cereal.grain(val); shouldEqual(val, true);
    cereal.grain(val); shouldEqual(val, false);
    cereal.grain(val); shouldEqual(val, true);
    cereal.grain(val); shouldEqual(val, false);
    cereal.grain(val); shouldEqual(val, false);
    cereal.grain(val); shouldEqual(val, true);
    cereal.value!bool.shouldThrow!RangeError; //no more bytes
}


@("decode.byte")
unittest {
    auto cereal = Decerealiser([0x0, 0x2, 0xfc]);
    cereal.value!byte.shouldEqual(0);
    cereal.value!byte.shouldEqual(2);
    cereal.value!byte.shouldEqual(-4);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

@("decode.ref.byte")
unittest {
    import cerealed.cereal: grain;
    auto cereal = Decerealiser([0xfc]);
    byte val;
    cereal.grain(val);
    val.shouldEqual(-4);
}

@("decode.u.byte")
unittest {
    auto cereal = Decerealiser([0x0, 0x2, 0xfc]);
    cereal.value!ubyte.shouldEqual(0);
    cereal.value!ubyte.shouldEqual(2);
    cereal.value!ubyte.shouldEqual(252);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

@("decode.short")
unittest {
    auto cereal = Decerealiser([0xff, 0xfe, 0x0, 0x3]);
    cereal.value!short.shouldEqual(-2);
    cereal.value!short.shouldEqual(3);
    shouldThrow!RangeError(cereal.value!short); //no more bytes
}

@("decode.ref.short")
unittest {
    import cerealed.cereal: grain;
    auto cereal = Decerealiser([0xff, 0xfe]);
    short val;
    cereal.grain(val);
    val.shouldEqual(-2);
}

@("decode.int")
unittest {
    auto cereal = Decerealiser([ 0xff, 0xf0, 0xbd, 0xc0]);
    cereal.value!int.shouldEqual(-1_000_000);
    shouldThrow!RangeError(cereal.value!int); //no more bytes
}

@("decode.ref.int")
unittest {
    import cerealed.cereal: grain;
    auto cereal = Decerealiser([0xff, 0xf0, 0xbd, 0xc0]);
    int val;
    cereal.grain(val);
    val.shouldEqual(-1_000_000);
}

@("decode.long")
unittest {
    auto cereal = Decerealiser([ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2]);
    cereal.value!long.shouldEqual(1);
    cereal.value!long.shouldEqual(2);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

@("decode.ref.long")
unittest {
    import cerealed.cereal: grain;
    auto cereal = Decerealiser([ 0, 0, 0, 0, 0, 0, 0, 1]);
    long val;
    cereal.grain(val);
    val.shouldEqual(1);
}


@("decode.big.u.long")
unittest {
    auto dec = Decerealiser([0xd8, 0xbf, 0xc7, 0xcd, 0x2d, 0x9b, 0xa1, 0xb1]);
    dec.value!ulong.shouldEqual(0xd8bfc7cd2d9ba1b1);
    shouldThrow!RangeError(dec.value!ubyte); //no more bytes
}


@("decode.double")
unittest {
    auto cereal = Decerealiser([ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2]);
    shouldNotThrow(cereal.value!double);
    shouldNotThrow(cereal.value!double);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

@("decode.chars")
unittest {
    auto cereal = Decerealiser([ 0xff, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff ]);
    cereal.value!char.shouldEqual(0xff);
    cereal.value!wchar.shouldEqual(0xffff);
    cereal.value!dchar.shouldEqual(0x0000ffff);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

@("decode.ref.char")
unittest {
    import cerealed.cereal: grain;
    auto cereal = Decerealiser([0xff]);
    char val;
    cereal.grain(val);
    val.shouldEqual(0xff);
}


@("decode.array")
unittest {
    auto cereal = Decerealiser([ 0, 3, 0, 0, 0, 2, 0, 0, 0, 6, 0, 0, 0, 9 ]);
    cereal.value!(int[]).shouldEqual([ 2, 6, 9 ]);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

@("decode.ref.array")
unittest {
    import cerealed.cereal: grain;
    auto cereal = Decerealiser([0, 1, 0, 0, 0, 2]);
    int[] val;
    cereal.grain(val);
    val.shouldEqual([2]);
}

@("decode.array.long.length")
unittest {
    auto cereal = Decerealiser([ 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 2, 0, 0, 0, 6, 0, 0, 0, 9 ]);
    cereal.value!(int[], long).shouldEqual([ 2, 6, 9 ]);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

@("decode.assoc.array")
unittest {
    auto cereal = Decerealiser([ 0, 2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 6 ]);
    cereal.value!(int[int]).shouldEqual([ 1:2, 3:6]);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}


@("decode.ref.assoc.array")
unittest {
    import cerealed.cereal: grain;
    auto cereal = Decerealiser([0, 1, 0, 0, 0, 2, 0, 0, 0, 3]);
    int[int] val;
    cereal.grain(val);
    val.shouldEqual([2:3]);
}

@("decode.assoc.array.int.length")
unittest {
    auto cereal = Decerealiser([ 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 6 ]);
    cereal.value!(int[int], int).shouldEqual([ 1:2, 3:6]);
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

@("decode.string")
unittest {
    auto cereal = Decerealiser([0, 5, 'a', 't', 'o', 'y', 'n']);
    cereal.value!(string).shouldEqual("atoyn");
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

@("decode.ref.string")
unittest {
    import cerealed.cereal: grain;
    auto cereal = Decerealiser([0, 5, 'a', 't', 'o', 'y', 'n']);
    string val;
    cereal.grain(val);
    val.shouldEqual("atoyn");
    cereal.value!ubyte.shouldThrow!RangeError; //no more bytes
}

@("decode.bits")
unittest {
    auto cereal = Decerealiser([ 0x9e, 0xea]);
    //1001 1110 1110 1010 or
    //100 111 10111 01 010
    cereal.readBits(3).shouldEqual(4);
    cereal.readBits(3).shouldEqual(7);
    cereal.readBits(5).shouldEqual(23);
    cereal.readBits(2).shouldEqual(1);
    cereal.readBits(3).shouldEqual(2);

    cereal.reset();
    cereal.readBits(3).shouldEqual(4);
    cereal.readBits(3).shouldEqual(7);
    cereal.readBits(5).shouldEqual(23);
    cereal.readBits(2).shouldEqual(1);
    cereal.readBits(3).shouldEqual(2);
}

@("decode.bits.multi.byte")
unittest {
    auto cereal = Decerealiser([ 0x9e, 0xea]);
    cereal.readBits(9).shouldEqual(317);
    cereal.readBits(7).shouldEqual(0x6a);
}

@("decode.string.array")
unittest {
    auto dec = Decerealiser([ 0, 3,
                              0, 3, 'f', 'o', 'o',
                              0, 4, 'w', '0', '0', 't',
                              0, 2, 'l', 'i']);
    dec.value!(string[]).shouldEqual(["foo", "w00t", "li"]);
}

@("Decode enum with bad value")
unittest {
    struct Foo {
        enum Type {
            foo,
            bar,
        }
        Type type;
    }

    Decerealiser([0, 0, 0, 42]).value!(Foo.Type).shouldThrow;
    Decerealiser([0, 0, 0, 42]).value!Foo.shouldThrow;
}


@("Throws if length of array is larger than packet")
unittest {
    Decerealiser([0, 8, 1, 2]).value!(ubyte[]).shouldThrowWithMessage(
        "Not enough bytes left to decerealise ubyte[] of 8 elements\n" ~
        "Bytes left: 2, Needed: 8, bytes: [1, 2]");

    Decerealiser([0, 8, 1, 2]).value!(int[]).shouldThrowWithMessage(
        "Not enough bytes left to decerealise int[] of 8 elements\n" ~
        "Bytes left: 2, Needed: 32, bytes: [1, 2]");
}

@("Types with @disable this can be encoded/decoded")
@safe
unittest {
    static struct NoDefault {
        ubyte i;
        @disable this();
        this(ubyte i) { this.i = i; }
    }

    [5].decerealise!NoDefault.shouldEqual(NoDefault(5));
}
