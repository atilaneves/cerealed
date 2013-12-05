module cerealed.cereal;

public import cerealed.attrs;
import std.traits;
import std.conv;
import std.algorithm;

class Cereal {
public:

    enum Type { Write, Read }

    abstract Type type() const;
    abstract ulong bytesLeft() const;

    //catch all signed numbers and forward to reinterpret
    void grain(T)(ref T val) @safe if(isSigned!T || isBoolean!T || is(T == char) || isFloatingPoint!T) {
        grainReinterpret(val);
    }

    void grain(T)(ref T val) @safe if(is(T == ubyte)) {
        grainUByte(val);
    }

    void grain(T)(ref T val) @safe if(is(T == ushort)) {
        ubyte valh = (val >> 8);
        ubyte vall = val & 0xff;
        grainUByte(valh);
        grainUByte(vall);
        val = (valh << 8) + vall;
    }

    void grain(T)(ref T val) @safe if(is(T == uint)) {
        ubyte val0 = (val >> 24);
        ubyte val1 = cast(ubyte)(val >> 16);
        ubyte val2 = cast(ubyte)(val >> 8);
        ubyte val3 = val & 0xff;
        grainUByte(val0);
        grainUByte(val1);
        grainUByte(val2);
        grainUByte(val3);
        val = (val0 << 24) + (val1 << 16) + (val2 << 8) + val3;
    }

    void grain(T)(ref T val) @safe if(is(T == ulong)) {
        immutable oldVal = val;
        val = 0;

        for(int i = T.sizeof - 1; i >= 0; --i) {
            immutable shift = (T.sizeof - i) * 8;
            ubyte byteVal = (oldVal >> shift) & 0xff;
            grainUByte(byteVal);
            val |= cast(T)byteVal << shift;
        }
    }

    void grain(T)(ref T val) @trusted if(is(T == wchar)) {
        grain(*cast(ushort*)&val);
    }

    void grain(T)(ref T val) @trusted if(is(T == dchar)) {
        grain(*cast(uint*)&val);
    }

    void grain(T, U = ushort)(ref T val) @safe if(isArray!T && !is(T == string)) {
        U length = cast(U)val.length;
        grain(length);
        static if(isMutable!T) {
            if(val.length == 0) { //decoding
                val.length = cast(uint)length;
            }
        }
        foreach(ref e; val) grain(e);
    }

    void grain(T, U = ushort)(ref T val) @trusted if(is(T == string)) {
        U length = cast(U)val.length;
        grain(length);

        auto values = new char[length];
        if(val.length != 0) { //copy string
            values[] = val[];
        }

        foreach(ref e; values) {
            grain(e);
        }
        val = cast(string)values;
    }

    void grain(T, U = ushort)(ref T val) @trusted if(isAssociativeArray!T) {
        U length = cast(U)val.length;
        grain(length);
        const keys = val.keys;

        for(U i = 0; i < length; ++i) {
            KeyType!T k = keys.length ? keys[i] : KeyType!T.init;
            auto v = keys.length ? val[k] : ValueType!T.init;

            grain(k);
            grain(v);
            val[k] = v;
        }
    }

    void grain(T)(ref T val) @trusted if(isAggregateType!T) {
        static if(__traits(hasMember, val, "accept") &&
                  __traits(compiles, val.accept(this))) {
            //custom serialisation, let the aggreagate do its thing
            static assert(!__traits(hasMember, val, "postBlit"),
                          "Cannot define both accept and postBlit");
            val.accept(this);
        } else {
            //normal serialisation, go through each member and possibly serialise
            grainAllMembers(val);
            static if(__traits(hasMember, val, "postBlit") &&
                      __traits(compiles, val.postBlit(this))) {
                //semi-custom serialisation, do post blit
                val.postBlit(this);
            }
        }
    }

    void grainAllMembers(T)(ref T val) @trusted {
        /*grains all members of an aggregate type*/
        static if(is(T == class)) {
            //do base classes first or else the order is wrong
            foreach(base; BaseTypeTuple!T) {
                grainAllMembersImpl!base(val);
            }
        }
        grainAllMembersImpl!T(val);
    }

    private void grainAllMembersImpl(ActualType, ValType)(ref ValType val) @trusted {
        foreach(member; __traits(derivedMembers, ActualType)) {
            //makes sure to only serialise members that make sense, i.e. data
            static if(__traits(compiles, grainMemberWithAttr!member(val))) {
                grainMemberWithAttr!member(val);
            }
        }
    }

    void grainMemberWithAttr(string member, T)(ref T val) @trusted {
        /**(De)serialises one member taking into account its attributes*/
        import std.typetuple;
        enum noCerealIndex = staticIndexOf!(NoCereal, __traits(getAttributes,
                                                               __traits(getMember, val, member)));
        enum rawArrayIndex = staticIndexOf!(RawArray, __traits(getAttributes,
                                                               __traits(getMember, val, member)));
        //only serialise if the member doesn't have @NoCereal
        static if(noCerealIndex == -1) {
            alias attrs = Filter!(isABitsStruct, __traits(getAttributes,
                                                          __traits(getMember, val, member)));
            static assert(attrs.length == 0 || attrs.length == 1,
                                  "Too many Bits!N attributes!");
            static if(attrs.length == 0) {
                //normal case, no Bits attributes
                static if(rawArrayIndex == -1) {
                    grain(__traits(getMember, val, member));
                } else {
                    grainRawArray(__traits(getMember, val, member));
                }
            } else {
                //Bits attributes, store it in less bits than fits
                enum bits = getNumBits!(attrs[0]);
                grainBitsT(__traits(getMember, val, member), bits);
            }
        }
    }

    void grainRawArray(T)(ref T[] val) @trusted {
        //can't use virtual functions due to template parameter
        if(type == Type.Read) {
            val.length = 0;
            while(bytesLeft) {
                val.length++;
                grain(val[$ - 1]);
            }
        } else {
            foreach(ref t; val) grain(t);
        }
    }

protected:

    abstract void grainUByte(ref ubyte val) @safe;
    abstract void grainBits(ref uint val, int bits) @safe;

private:

    void grainBitsT(T)(ref T val, int bits) @safe {
        uint realVal = val;
        grainBits(realVal, bits);
        val = cast(T)realVal;
    }

    void grainReinterpret(T)(ref T val) @trusted {
        auto ptr = cast(CerealPtrType!T)(&val);
        grain(*ptr);
    }
}

private template CerealPtrType(T) {
    static if(is(T == bool) || is(T == char)) {
        alias ubyte* CerealPtrType;
    } else static if(is(T == float)) {
        alias uint* CerealPtrType;
    } else static if(is(T == double)) {
        alias ulong* CerealPtrType;
    } else {
       import std.traits;
       alias Unsigned!T* CerealPtrType;
    }
}
