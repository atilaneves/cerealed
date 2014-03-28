module cerealed.cereal;

public import cerealed.attrs;
import cerealed.traits;
import std.traits;
import std.conv;
import std.algorithm;
import std.range;

enum CerealType { WriteBytes, ReadBytes };

void grain(C, T)(auto ref C cereal, ref T val) if(isCereal!C && is(T == ubyte)) {
    cereal.grainUByte(val);
}

//catch all signed numbers and forward to reinterpret
void grain(C, T)(auto ref C cereal, ref T val) @safe if(isCereal!C && !is(T == enum) &&
                                                        (isSigned!T || isBoolean!T ||
                                                         is(T == char) || isFloatingPoint!T)) {
    cereal.grainReinterpret(val);
}

// If the type is an enum, get the unqualified base type and cast it to that.
void grain(C, T)(auto ref C cereal, ref T val) @safe if(isCereal!C && is(T == enum)) {
    alias Unqual!(OriginalType!(T)) BaseType;
    cereal.grain( cast(BaseType)val );
}


void grain(C, T)(auto ref C cereal, ref T val) @trusted if(isCereal!C && is(T == wchar)) {
    cereal.grain(*cast(ushort*)&val);
}

void grain(C, T)(auto ref C cereal, ref T val) @trusted if(isCereal!C && is(T == dchar)) {
    cereal.grain(*cast(uint*)&val);
}

void grain(C, T)(auto ref C cereal, ref T val) @safe if(isCereal!C && is(T == ushort)) {
    ubyte valh = (val >> 8);
    ubyte vall = val & 0xff;
    cereal.grainUByte(valh);
    cereal.grainUByte(vall);
    val = (valh << 8) + vall;
}

void grain(C, T)(auto ref C cereal, ref T val) @safe if(isCereal!C && is(T == uint)) {
    ubyte val0 = (val >> 24);
    ubyte val1 = cast(ubyte)(val >> 16);
    ubyte val2 = cast(ubyte)(val >> 8);
    ubyte val3 = val & 0xff;
    cereal.grainUByte(val0);
    cereal.grainUByte(val1);
    cereal.grainUByte(val2);
    cereal.grainUByte(val3);
    val = (val0 << 24) + (val1 << 16) + (val2 << 8) + val3;
}

void grain(C, T)(auto ref C cereal, ref T val) @safe if(isCereal!C && is(T == ulong)) {
    immutable oldVal = val;
    val = 0;

    for(int i = T.sizeof - 1; i >= 0; --i) {
        immutable shift = (T.sizeof - i) * 8;
        ubyte byteVal = (oldVal >> shift) & 0xff;
        cereal.grainUByte(byteVal);
        val |= cast(T)byteVal << shift;
    }
}

void grain(C, T, U = ushort)(auto ref C cereal, ref T val) @safe if(isInputCereal!C &&
                                                                    isInputRange!T && !isInfinite!T &&
                                                                    !isAssociativeArray!T) {
    enum hasLength = is(typeof((inout int = 0) { auto l = val.length; }));
    static assert(hasLength, text("Only InputRanges with .length accepted, not the case for ",
                                  fullyQualifiedName!T));
    U length = cast(U)val.length;
    cereal.grain(length);
    foreach(ref e; val) cereal.grain(e);
}

void grain(C, T, U = ushort)(auto ref C cereal, ref T val) @trusted if(isOutputCereal!C &&
                                                                       isOutputRange!(T, ubyte)) {
    U length = void;
    cereal.grain(length);

    static if(isArray!T) {
        if(val.length < length) val.length = cast(uint)length;
        foreach(ref e; val) cereal.grain(e);
    } else {
        for(U i = 0; i < cereal.bytesRemaining; ++i) {
            ubyte b = void;
            cereal.grain(b);

            enum hasOpOpAssign = is(typeof((inout int = 0) { val ~= b; }));
            static if(hasOpOpAssign) {
                val ~= b;
            } else {
                val.put(b);
            }
        }
    }
}

void grain(C, T, U = ushort)(auto ref C cereal, ref T val) @trusted if(isCereal!C && is(T == string)) {
    U length = cast(U)val.length;
    cereal.grain(length);

    static if(is(isInputCereal!C)) {
        //easier to read from a string
        foreach(e; val) cereal.grain(e);
    } else {
        auto values = new char[length];
        if(val.length != 0) { //copy string
            values[] = val[];
        }

        foreach(ref e; values) {
            cereal.grain(e);
        }
        val = cast(string)values;
    }
}


void grain(C, T, U = ushort)(auto ref C cereal, ref T val) @trusted if(isCereal!C && isAssociativeArray!T) {
    U length = cast(U)val.length;
    cereal.grain(length);
    const keys = val.keys;

    for(U i = 0; i < length; ++i) {
        KeyType!T k = keys.length ? keys[i] : KeyType!T.init;
        auto v = keys.length ? val[k] : ValueType!T.init;

        cereal.grain(k);
        cereal.grain(v);
        val[k] = v;
    }
}


private void grainReinterpret(C, T)(auto ref C cereal, ref T val) @trusted if(isCereal!C) {
    auto ptr = cast(CerealPtrType!T)(&val);
    cereal.grain(*ptr);
}


class CerealT(Cereal) {
public:

    this(Cereal cereal) {
        _cereal = cereal;
    }

    //catch all signed numbers and forward to reinterpret
    final void grain(T)(ref T val) @safe if(!is(T == enum) &&
                                            (isSigned!T || isBoolean!T || is(T == char) || isFloatingPoint!T)) {
        grainReinterpret(val);
    }

    // If the type is an enum, get the unqualified base type and cast it to that.
    final void grain(T)(ref T val) @safe if(is(T == enum)) {
        alias Unqual!(OriginalType!(T)) BaseType;
        grain( cast(BaseType)val );
    }

    final void grain(T)(ref T val) @safe if(is(T == ubyte)) {
        _cereal.grainUByte(val);
    }

    final void grain(T)(ref T val) @safe if(is(T == ushort)) {
        ubyte valh = (val >> 8);
        ubyte vall = val & 0xff;
        _cereal.grainUByte(valh);
        _cereal.grainUByte(vall);
        val = (valh << 8) + vall;
    }

    final void grain(T)(ref T val) @safe if(is(T == uint)) {
        ubyte val0 = (val >> 24);
        ubyte val1 = cast(ubyte)(val >> 16);
        ubyte val2 = cast(ubyte)(val >> 8);
        ubyte val3 = val & 0xff;
        _cereal.grainUByte(val0);
        _cereal.grainUByte(val1);
        _cereal.grainUByte(val2);
        _cereal.grainUByte(val3);
        val = (val0 << 24) + (val1 << 16) + (val2 << 8) + val3;
    }

    final void grain(T)(ref T val) @safe if(is(T == ulong)) {
        immutable oldVal = val;
        val = 0;

        for(int i = T.sizeof - 1; i >= 0; --i) {
            immutable shift = (T.sizeof - i) * 8;
            ubyte byteVal = (oldVal >> shift) & 0xff;
            _cereal.grainUByte(byteVal);
            val |= cast(T)byteVal << shift;
        }
    }

    final void grain(T)(ref T val) @trusted if(is(T == wchar)) {
        grain(*cast(ushort*)&val);
    }

    final void grain(T)(ref T val) @trusted if(is(T == dchar)) {
        grain(*cast(uint*)&val);
    }

    final void grain(T, U = ushort)(ref T val) @trusted if(isInputRange!T && !isInfinite!T && !isArray!T) {
        enum hasLength = is(typeof((inout int = 0) { auto l = val.length; }));
        static assert(hasLength, text("Only InputRanges with .length accepted, not the case for ",
                                      fullyQualifiedName!T));
        assert(_cereal.type() == CerealType.WriteBytes, "InputRange cannot be deserialised");
        U length = cast(U)val.length;
        grain(length);
        foreach(ref e; val) grain(e);
    }

    final void grain(R, U = ushort)(ref R output) @trusted if(isOutputRange!(R, ubyte) && !isArray!R) {
        assert(_cereal.type() == CerealType.ReadBytes, "OutputRanges can only be deserialised");
        U length = void;
        grain(length);
        for(U i = 0; i < length; ++i) {
            ubyte b = void;
            grain(b);
            output.put(b);
        }
    }

    final void grain(T, U = ushort)(ref T val) @safe if(isArray!T && !is(T == string)) {
        U length = cast(U)val.length;
        grain(length);
        static if(isMutable!T) {
            if(val.length == 0) { //decoding
                val.length = cast(uint)length;
            }
        }
        foreach(ref e; val) grain(e);
    }

    final void grain(T, U = ushort)(ref T val) @trusted if(is(T == string)) {
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

    final void grain(T, U = ushort)(ref T val) @trusted if(isAssociativeArray!T) {
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

    final void grain(T)(ref T val) @trusted if(isAggregateType!T && !isInputRange!T && !isOutputRange!(T, ubyte)) {

        enum hasAccept   = is(typeof((inout int = 0) { val.accept(this); }));
        enum hasPostBlit = is(typeof((inout int = 0) { val.postBlit(this); }));

        static if(hasAccept) { //custom serialisation
            static assert(!hasPostBlit, "Cannot define both accept and postBlit");
            val.accept(this);
        } else { //normal serialisation, go through each member and possibly serialise
            grainAllMembers(val);
            static if(hasPostBlit) { //semi-custom serialisation, do post blit
                val.postBlit(this);
            }
        }
    }

    final void grain(T)(ref T val) @safe if(isPointer!T) {
        import std.traits;
        alias ValueType = PointerTarget!T;
        if(_cereal.type() == CerealType.ReadBytes && val is null) val = new ValueType;
        grain(*val);
    }

    final void grainAllMembers(T)(ref T val) @safe if(is(T == struct)) {
        grainAllMembersImpl!T(val);
    }

    final void grainAllMembers(T)(ref T val) @trusted if(is(T == class)) {
        assert(_cereal.type() == CerealType.ReadBytes || val !is null, "null value cannot be serialised");

        enum hasDefaultConstructor = is(typeof((inout int = 0) { val = new T; }));
        static if(hasDefaultConstructor) {
            if(_cereal.type() == CerealType.ReadBytes && val is null) val = new T;
        } else {
            assert(val !is null, text("Cannot deserialise into null value. ",
                                      "Possible cause: no default constructor for ",
                                      fullyQualifiedName!T, "."));
        }

        //check to see if child class that was registered
        if(!_cereal.grainChildClass(val)) {
            grainClassImpl(val);
        }
    }

    final void grainMemberWithAttr(string member, T)(ref T val) @trusted {
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

    final void grainRawArray(T)(ref T[] val) @trusted {
        //can't use virtual functions due to template parameter
        if(_cereal.type() == CerealType.ReadBytes) {
            val.length = 0;
            while(_cereal.bytesLeft()) {
                val.length++;
                grain(val[$ - 1]);
            }
        } else {
            foreach(ref t; val) grain(t);
        }
    }

protected:

    final void grainClassImpl(T)(ref T val) @safe if(is(T == class)) {
        //do base classes first or else the order is wrong
        grainBaseClasses(val);
        grainAllMembersImpl!T(val);
    }

private:

    Cereal _cereal;

    final void grainBitsT(T)(ref T val, int bits) @safe {
        uint realVal = val;
        _cereal.grainBits(realVal, bits);
        val = cast(T)realVal;
    }

    final void grainReinterpret(T)(ref T val) @trusted {
        auto ptr = cast(CerealPtrType!T)(&val);
        grain(*ptr);
    }

    final void grainBaseClasses(T)(ref T val) @safe if(is(T == class)) {
        foreach(base; BaseTypeTuple!T) {
            grainAllMembersImpl!base(val);
        }
    }


    final void grainAllMembersImpl(ActualType, ValType)(ref ValType val) @trusted {
        foreach(member; __traits(derivedMembers, ActualType)) {
            //makes sure to only serialise members that make sense, i.e. data
            enum isMemberVariable = is(typeof(
                (inout int = 0) {
                    __traits(getMember, val, member) = __traits(getMember, val, member).init;
                }));
            static if(isMemberVariable) {
                grainMemberWithAttr!member(val);
            }
        }
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
       alias Unsigned!T* CerealPtrType;
    }
}
