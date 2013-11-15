cerealed
=============

Binary serialisation library for D. Minimal to no boilerplate necessary. Example usage:

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
automatically, but can be opted out via the @NoCereal attribute. Also importantly,
members to be serialised in a certain number of bits (important for binary protocols)
are signalled with the @Bits attribute with a compile-time integer specifying the
number of bits to use.

    struct MyStruct {
        ubyte mybyte1;
        @NoCereal uint nocereal1; //won't be serialised
        @Bits!4 nibble;
        @Bits!1 bit;
        @Bits!3 bits3;
        ubyte mybyte2;
    }

    auto cereal = new Cerealiser();
    cereal ~= MyStruct(3, 123, 14, 1, 2);
    assert(cereal.bytes == [ 3, 0xea /*1110 1 010*/, 2]);

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
and postBlit is called to fix things up. Example below.

    struct CustomStruct {
        ubyte mybyte;
        ushort myshort;
        void postBlit(Cereal cereal) {
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
