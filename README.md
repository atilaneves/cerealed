cerealed
=============

Binary serialisation library for D. Minimal to no boilerplate necessary.
The tests in the [tests directory](tests) depend on
[unit-threaded](https://github.com/atilaneves/unit-threaded) to run.

Example usage:

    auto cerealiser = new Cerealiser(); //UK spelling
    cerealiser ~= 5; //int
    cerealiser ~= cast(ubyte)42;
    assert(cerealiser.bytes == [ 0, 0, 0, 5, 42]);

    auto deceralizer = new Decerealizer([ 0, 0, 0, 5, 42]); //US spelling works too
    assert(decerealizer.value!int == 5);
    assert(decerealizer.value!ubyte == 42);

It can also handle strings, associative arrays, arrays, chars, etc.
What about structs? No boilerplate necessary, compile-time reflection does it for you.
The example below shows off a few features. First and foremost, members are serialised
automatically, but can be opted out via the `@NoCereal` attribute. Also importantly,
members to be serialised in a certain number of bits (important for binary protocols)
are signalled with the `@Bits` attribute with a compile-time integer specifying the
number of bits to use.

    struct MyStruct {
        ubyte mybyte1;
        @NoCereal uint nocereal1; //won't be serialised
        @Bits!4 ubyte nibble;
        @Bits!1 ubyte bit;
        @Bits!3 ubyte bits3;
        ubyte mybyte2;
    }

    auto cereal = new Cerealiser();
    cereal ~= MyStruct(3, 123, 14, 1, 42);
    assert(cereal.bytes == [ 3, 0xea /*1110 1 010*/, 42]);

What if custom serialisation is needed and the default, even with opt-outs, won't work?
If an aggregate type defines a member function `void accept(Cereal)` it will be used
instead. To get the usual automatic serialisation from within the custom `accept`,
the `grainAllMembers` member function of Cereal can be called, as shown in the
example below. This function takes a ref argument so rvalues need not apply.

The function to use on `Cereal` to marshall or unmarshall a particular value is `grain`.
This is essentially what `Cerealiser.~=` and `Decerealiser.value` are calling behind
the scenes.

    struct CustomStruct {
        ubyte mybyte;
        ushort myshort;
        void accept(Cereal cereal) {
             //do NOT call cereal.grain(this), that would cause an infinite loop
             cereal.grainAllMembers(this);
             ubyte otherbyte = 4; //make it an lvalue
             cereal.grain(otherbyte);
        }
    }

    auto cerealiser = new Cerealiser();
    cerealiser ~= CustomStruct(1, 2);
    assert(cerealiser.bytes == [ 1, 0, 2, 4]);

    //because of the custom serialisation, passing in just [1, 0, 2] would throw
    auto decerealiser = new Decerealiser([1, 0, 2, 4]);
    assert(decerealiser.value!CustomStruct == CustomStruct(1, 2));


The other option when custom serialisation is needed, to avoid boilerplate, is to
define a `void postBlit(Cereal cereal)` function instead of `accept`. The
marshalling or unmarshalling is done as it would in the absence of customisation,
and postBlit is called to fix things up. It is a compile-time error to
define both `accept` and `postBlit`. Example below.

    struct CustomStruct {
        ubyte mybyte;
        ushort myshort;
        @NoCereal ubyte otherByte;
        void postBlit(Cereal cereal) {
             //no need to handle mybyte and myshort, already done
             if(mybyte == 1) {
                 cereal.grain(otherByte);
             }
        }
    }

    {
        auto cereal = new Cerealiser();
        cereal ~= CustomStruct(1, 2);
        assert(cereal.bytes == [ 1, 0, 2, 4]);
    }

    {
        auto cereal = new Cerealiser();
        cereal ~= CustomStruct(3, 2);
        assert(cereal.bytes == [ 1, 0, 2]);
    }

For more examples of how to serialise structs, check the [tests](tests) directory
or real-world usage in my [MQTT](https://github.com/atilaneves/mqtt) broker
also written in D.

Arrays are by default serialised with a ushort denoting array length followed
by the array contents. It happens often enough that networking protocols
have explicit length parameters for the whole packet and that array lengths
are implicitly determined from this. For this use case, the `@RawArray`
attribute tells `cerealed` to not add the length parameter.

    private struct StringsStruct {
        ubyte mybyte;
        @RawArray string[] strings;
    }

    auto enc = new Cerealiser();
    auto strs = StringsStruct(5, ["foo", "foobar", "ohwell"]);
    enc ~= strs;
    //no length encoding for the array, but strings still get a length each
    const bytes = [ 5, 0, 3, 'f', 'o', 'o', 0, 6, 'f', 'o', 'o', 'b', 'a', 'r',
                    0, 6, 'o', 'h', 'w', 'e', 'l', 'l'];
    assert(enc.bytes == bytes);

    auto dec = new Decerealiser(bytes);
    assert(dec.value!StringsStruct ==  strs);

Related Projects
----------------
- [orange](https://github.com/jacob-carlborg/orange).