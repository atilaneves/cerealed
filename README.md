cerealed
=============
[![Build Status](https://travis-ci.org/atilaneves/cerealed.png?branch=master)](https://travis-ci.org/atilaneves/cerealed)

[My DConf 2014 talk mentioning Cerealed](https://www.youtube.com/watch?v=xpImt14KTdc).

Binary serialisation library for D. Minimal to no boilerplate necessary. Example usage:

```d
    import cerealed;

    assert(cerealise(5) == [0, 0, 0, 5]); // returns ubyte[]
    cerealise!(a => assert(a == [0, 0, 0, 5]))(5); // faster than using the bytes directly

    assert(decerealise!int([0, 0, 0, 5]) == 5);

    struct Foo { int i; }
    const foo = Foo(5);
    // alternate spelling
    assert(foo.cerealize.decerealize!Foo == foo);
```

The example below shows off a few features. First and foremost, members are serialised
automatically, but can be opted out via the `@NoCereal` attribute. Also importantly,
members to be serialised in a certain number of bits (important for binary protocols)
are signalled with the `@Bits` attribute with a compile-time integer specifying the
number of bits to use.

```d
    struct MyStruct {
        ubyte mybyte1;
        @NoCereal uint nocereal1; //won't be serialised
        @Bits!4 ubyte nibble;
        @Bits!1 ubyte bit;
        @Bits!3 ubyte bits3;
        ubyte mybyte2;
    }

    assert(MyStruct(3, 123, 14, 1, 42).cerealise == [ 3, 0xea /*1110 1 010*/, 42]);
```

What if custom serialisation is needed and the default, even with opt-outs, won't work?
If an aggregate type defines a member function `void accept(C)(ref C cereal)` it will be used
instead. To get the usual automatic serialisation from within the custom `accept`,
the `grainAllMembers` member function of Cereal can be called, as shown in the
example below. This function takes a ref argument so rvalues need not apply.

The function to use on `Cereal` to marshall or unmarshall a particular value is `grain`.
This is essentially what `Cerealiser.~=` and `Decerealiser.value` are calling behind
the scenes (and therefore `cerealise` and `decerealise`).

```d
    struct CustomStruct {
        ubyte mybyte;
        ushort myshort;
        void accept(C)(auto ref C cereal) {
             //do NOT call cereal.grain(this), that would cause an infinite loop
             cereal.grainAllMembers(this);
             ubyte otherbyte = 4; //make it an lvalue
             cereal.grain(otherbyte);
        }
    }

    assert(CustomStruct(1, 2).cerealise == [ 1, 0, 2, 4]);

    //because of the custom serialisation, passing in just [1, 0, 2] would throw
    assert([1, 0, 2, 4].decerealise!CustomStruct == CustomStruct(1, 2));
```

The other option when custom serialisation is needed that avoids boilerplate is to
define a `void postBlit(C)(ref C cereal)` function instead of `accept`. The
marshalling or unmarshalling is done as it would in the absence of customisation,
and `postBlit` is called to fix things up. It is a compile-time error to
define both `accept` and `postBlit`. Example below.

```d
    struct CustomStruct {
        ubyte mybyte;
        ushort myshort;
        @NoCereal ubyte otherByte;
        void postBlit(C)(auto ref C cereal) {
             //no need to handle mybyte and myshort, already done
             if(mybyte == 1) {
                 cereal.grain(otherByte);
             }
        }
    }

    assert(CustomStruct(1, 2).cerealise == [ 1, 0, 2, 4]);
    assert(CustomStruct(3, 2).cerealise == [ 1, 0, 2]);
```

For more examples of how to serialise structs, check the [tests](tests) directory
or real-world usage in my [MQTT broker](https://github.com/atilaneves/mqtt)
also written in D.

Arrays are by default serialised with a ushort denoting array length followed
by the array contents. It happens often enough that networking protocols
have explicit length parameters for the whole packet and that array lengths
are implicitly determined from this. For this use case, the `@RestOfPacket`
attribute tells `cerealed` to not add the length parameter. As the name implies,
it will "eat" all bytes until there aren't any left.

```d
    private struct StringsStruct {
        ubyte mybyte;
        @RestOfPacket string[] strings;
    }

    //no length encoding for the array, but strings still get a length each
    const bytes = [ 5, 0, 3, 'f', 'o', 'o', 0, 6, 'f', 'o', 'o', 'b', 'a', 'r',
                    0, 6, 'o', 'h', 'w', 'e', 'l', 'l'];
    const strs = StringStruct(5, ["foo", "foobar", "ohwell"]);
    assert(strs.cerealise == bytes);
    assert(bytes.decerealise!StringsStruct ==  strs);
```

Derived classes can be serialised via a reference to the base class, but the
child class must be registered first:

```d
    class BaseClass  { int a; this(int a) { this.a = a; }}
    class ChildClass { int b; this(int b) { this.b = b; }}
    Cereal.registerChildClass!ChildClass;
    BaseClass obj = ChildClass(3, 7);
    assert(obj.cerealise == [0, 0, 0, 3, 0, 0, 0, 7]);
```

There is now support for InputRange and OutputRange objects. Examples can
be found in the [tests directory](tests/range.d)

Advanced Usage
---------------
Frequently in networking programming, the packets themselves encode the length
of elements to follow. This happens often enough that Cerealed has two UDAs
to automate this kind of serialisation: `@ArrayLength` and `@LengthInBytes`.
The former specifies how to get the length of an array (usually a variable)
The latter specifies how many bytes the array takes. Examples:

```d
    struct Packet {
        ushort length;
        @ArrayLength("length") ushort[] array;
    }
    auto pkt = decerealise!Packet([
        0, 3, //length
        0, 1, 0, 2, 0, 3]); //array of 3 ushorts
    assert(pkt.length == 3);
    assert(pkt.array == [1, 2, 3]);

    struct Packet {
        static struct Header {
            ubyte ub;
            ubyte totalLength;
        }
        enum headerSize = unalignedSizeof!Header; //2 bytes

        Header header;
        @LengthInBytes("totalLength - headerSize") ushort[] array;
    }
    auto pkt = decerealise!Packet([
        7, //ub1
        6, //totalLength in bytes
        0, 1, 0, 2]); //array of 2 ushorts
    assert(pkt.ub1 == 7);
    assert(pkt.totalLength == 6);
    assert(pkt.array == [1, 2]);
```

Related Projects
----------------
- [orange](https://github.com/jacob-carlborg/orange).
- [msgpack-d](https://github.com/msgpack/msgpack-d).
