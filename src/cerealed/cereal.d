module cerealed.cereal;

public import cerealed.attrs;
import cerealed.traits;
import std.traits;
import std.conv;
import std.algorithm;
import std.range;
import std.typetuple;

class CerealException: Exception {
    this(string msg) @safe pure {
        super(msg);
    }
}

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
    T newVal;
    for(int i = 0; i < T.sizeof; ++i) {
        immutable shiftBy = 64 - (i + 1) * T.sizeof;
        ubyte byteVal = (val >> shiftBy) & 0xff;
        cereal.grainUByte(byteVal);
        newVal |= (cast(T)byteVal << shiftBy);
    }
    val = newVal;
}

enum hasByteElement(T) = is(Unqual!(ElementType!T): ubyte);

void grain(C, T, U = ushort)(auto ref C cereal, ref T val) @trusted if(isCerealiser!C &&
                                                                       isInputRange!T && !isInfinite!T &&
                                                                       !is(T == string) &&
                                                                       !isStaticArray!T &&
                                                                       !isAssociativeArray!T) {
    enum hasLength = is(typeof(() { auto l = val.length; }));
    static assert(hasLength, text("Only InputRanges with .length accepted, not the case for ",
                                  fullyQualifiedName!T));
    U length = cast(U)val.length;
    assert(length == val.length, "overflow");
    cereal.grain(length);

    static if(hasSlicing!(Unqual!T) && hasByteElement!T)
        cereal.grainRaw(cast(ubyte[])val.array);
    else
        foreach(ref e; val) cereal.grain(e);
}

void grain(C, T)(auto ref C cereal, ref T val) @safe if(isCereal!C && isStaticArray!T) {
    static if(hasByteElement!T)
        cereal.grainRaw(cast(ubyte[])val);
    else
        foreach(ref e; val) cereal.grain(e);
}

void grain(C, T, U = ushort)(auto ref C cereal, ref T val) @trusted if(isDecerealiser!C &&
                                                                       !isStaticArray!T &&
                                                                       isOutputRange!(T, ubyte)) {
    U length = void;
    cereal.grain(length);

    static if(isArray!T) {
        decerealiseArrayImpl(cereal, val, length);
    } else {
        for(U i = 0; i < length; ++i) {
            ubyte b = void;
            cereal.grain(b);

            enum hasOpOpAssign = is(typeof(() { val ~= b; }));
            static if(hasOpOpAssign) {
                val ~= b;
            } else {
                val.put(b);
            }
        }
    }
}

private void decerealiseArrayImpl(C, T, U = ushort)(auto ref C cereal, ref T val, U length) @safe
    if(is(T == E[], E)) {

    static if(hasByteElement!T) {
        val = cereal.grainRaw(length).dup;
    } else {
        if(val.length != length) val.length = cast(uint)length;
        assert(length == val.length, "overflow");

        foreach(ref e; val) cereal.grain(e);
    }
}

void grain(C, T, U = ushort)(auto ref C cereal, ref T val) @trusted if(isDecerealiser!C &&
                                                                       !isOutputRange!(T, ubyte) &&
                                                                       isDynamicArray!T && !is(T == string)) {
    U length = void;
    cereal.grain(length);
    decerealiseArrayImpl(cereal, val, length);
}

void grain(C, T, U = ushort)(auto ref C cereal, ref T val) @trusted if(isCereal!C && is(T == string)) {
    U length = cast(U)val.length;
    assert(length == val.length, "overflow");
    cereal.grain(length);

    static if(isCerealiser!C)
        cereal.grainRaw(cast(ubyte[])val);
    else
        val = cast(string)cereal.grainRaw(length);
}


void grain(C, T, U = ushort)(auto ref C cereal, ref T val) @trusted if(isCereal!C && isAssociativeArray!T) {
    U length = cast(U)val.length;
    assert(length == val.length, "overflow");
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

void grain(C, T)(auto ref C cereal, ref T val) @safe if(isCereal!C && isPointer!T) {
    import std.traits;
    alias ValueType = PointerTarget!T;
    static if(isDecerealiser!C) {
        if(val is null) val = new ValueType;
    }
    cereal.grain(*val);
}

private template canCall(C, T, string func) {
    enum canCall = is(typeof(() { auto cer = C(); auto val = T.init; mixin("val." ~ func ~ "(cer);"); }));
    static if(!canCall && __traits(hasMember, T, func)) {
        pragma(msg, "Warning: '" ~ func ~
               "' function defined for ", T, ", but does not compile for Cereal ", C);
    }
}

void grain(C, T)(auto ref C cereal, ref T val) @trusted if(isCereal!C && isAggregateType!T &&
                                                           !isInputRange!T && !isOutputRange!(T, ubyte)) {
    enum canAccept   = canCall!(C, T, "accept");
    enum canPreBlit = canCall!(C, T, "preBlit");
    enum canPostBlit = canCall!(C, T, "postBlit");

    static if(canAccept) { //custom serialisation
        static assert(!canPostBlit && !canPreBlit, "Cannot define both accept and pre/postBlit");
        val.accept(cereal);
    } else { //normal serialisation, go through each member and possibly serialise
        static if(canPreBlit) {
            val.preBlit(cereal);
        }

        cereal.grainAllMembers(val);
        static if(canPostBlit) { //semi-custom serialisation, do post blit
            val.postBlit(cereal);
        }
    }
}

void grainAllMembers(C, T)(auto ref C cereal, ref T val) @safe if(isCereal!C && is(T == struct)) {
    cereal.grainAllMembersImpl!T(val);
}


void grainAllMembers(C, T)(auto ref C cereal, ref T val) @trusted if(isCereal!C && is(T == class)) {
    static if(isCerealiser!C) {
        assert(val !is null, "null value cannot be serialised");
    }

    enum hasDefaultConstructor = is(typeof(() { val = new T; }));
    static if(hasDefaultConstructor && isDecerealiser!C) {
        if(val is null) val = new T;
    } else {
        assert(val !is null, text("Cannot deserialise into null value. ",
                                  "Possible cause: no default constructor for ",
                                  fullyQualifiedName!T, "."));
    }

    cereal.grainClass(val);
}


void grainMemberWithAttr(string member, C, T)(auto ref C cereal, ref T val) @trusted if(isCereal!C) {
    /**(De)serialises one member taking into account its attributes*/
    enum noCerealIndex = staticIndexOf!(NoCereal, __traits(getAttributes,
                                                           __traits(getMember, val, member)));
    enum rawArrayIndex = staticIndexOf!(RawArray, __traits(getAttributes,
                                                           __traits(getMember, val, member)));
    //only serialise if the member doesn't have @NoCereal
    static if(noCerealIndex == -1) {
        alias bitsAttrs = Filter!(isABitsStruct, __traits(getAttributes,
                                                      __traits(getMember, val, member)));
        static assert(bitsAttrs.length == 0 || bitsAttrs.length == 1,
                      "Too many Bits!N attributes!");

        alias arrayLengths = Filter!(isArrayLengthStruct,
                                     __traits(getAttributes,
                                              __traits(getMember, val, member)));
        static assert(arrayLengths.length == 0 || arrayLengths.length == 1,
                      "Too many ArrayLength attributes");

        alias lengthInBytes = Filter!(isLengthInBytesStruct,
                                      __traits(getAttributes,
                                               __traits(getMember, val, member)));
        static assert(lengthInBytes.length == 0 || lengthInBytes.length == 1,
                      "Too many LengthInBytes attributes");

        static if(bitsAttrs.length == 1) {

            grainWithBitsAttr!(member, bitsAttrs[0])(cereal, val);

        } else static if(rawArrayIndex != -1) {

            cereal.grainRawArray(__traits(getMember, val, member));

        } else static if(arrayLengths.length > 0) {

            grainWithArrayLengthAttr!(member, arrayLengths[0].member)(cereal, val);

        } else static if(lengthInBytes.length > 0) {

            grainWithLengthInBytesAttr!(member, lengthInBytes[0].member)(cereal, val);

        } else {

            cereal.grain(__traits(getMember, val, member));

        }
    }
}

private void grainWithBitsAttr(string member, alias bitsAttr, C, T)(
    auto ref C cereal, ref T val) @safe if(isCereal!C) {

    enum numBits = getNumBits!(bitsAttr);
    enum sizeInBits = __traits(getMember, val, member).sizeof * 8;
    static assert(numBits <= sizeInBits,
                  text(fullyQualifiedName!T, ".", member, " is ", sizeInBits,
                       " bits long, which is not enough to store @Bits!", numBits));
    cereal.grainBitsT(__traits(getMember, val, member), numBits);
}

private void grainWithArrayLengthAttr(string member, string lengthMember, C, T)
    (auto ref C cereal, ref T val) @safe if(isCereal!C) {

    checkArrayAttrType!member(cereal, val);

    static if(isCerealiser!C) {
        cereal.grainRawArray(__traits(getMember, val, member));
    } else {
        immutable length = lengthOfArray!(member, lengthMember)(cereal, val);
        alias E = ElementType!(typeof(__traits(getMember, val, member)));

        if(length * E.sizeof  > cereal.bytesLeft) {
            throw new CerealException(text("@ArrayLength of ", length, " units of type ",
                                           E.stringof,
                                           " (", length * E.sizeof, " bytes) ",
                                           "larger than remaining byte array (",
                                           cereal.bytesLeft, " bytes)"));
        }

        mixin(q{__traits(getMember, val, member).length = length;});

        foreach(ref e; __traits(getMember, val, member)) cereal.grain(e);
    }
}

private void grainWithLengthInBytesAttr(string member, string lengthMember, C, T)
    (auto ref C cereal, ref T val) @safe if(isCereal!C) {

    checkArrayAttrType!member(cereal, val);

    static if(isCerealiser!C) {
        cereal.grainRawArray(__traits(getMember, val, member));
    } else {
        immutable length = lengthOfArray!(member, lengthMember)(cereal, val); //error handling

        if(length > cereal.bytesLeft) {
            alias E = ElementType!(typeof(__traits(getMember, val, member)));
            throw new CerealException(text("@LengthInBytes of ", length, " bytes ",
                                           "larger than remaining byte array (",
                                           cereal.bytesLeft, " bytes)"));
        }

        __traits(getMember, val, member).length = 0;

        while(cereal.bytesLeft) {
            __traits(getMember, val, member).length++;
            cereal.grain(__traits(getMember, val, member)[$ - 1]);
        }
    }
}

private void checkArrayAttrType(string member, C, T)(auto ref C cereal, ref T val) @safe if(isCereal!C) {
    alias M = typeof(__traits(getMember, val, member));
    static assert(is(M == E[], E),
                  text("@ArrayLength and @LengthInBytes not valid for ", member,
                       ": they can only be used on slices"));
}


private int lengthOfArray(string member, string lengthMember, C, T)(auto ref C cereal, ref T val)
    @safe if(isCereal!C) {
    int _tmpLen;
    mixin(q{with(val) _tmpLen = cast(int)(} ~ lengthMember ~ q{);});

    if(_tmpLen < 0)
        throw new CerealException(text("@LengthInBytes resulted in negative length ", _tmpLen));

    return _tmpLen;
}

void grainRawArray(C, T)(auto ref C cereal, ref T[] val) @trusted if(isCereal!C) {
    //can't use virtual functions due to template parameter
    static if(isDecerealiser!C) {
        val.length = 0;
        while(cereal.bytesLeft()) {
            val.length++;
            cereal.grain(val[$ - 1]);
        }
    } else {
        foreach(ref t; val) cereal.grain(t);
    }
}


/**
 * To be used when the length of the array is known at run-time based on the value
 * of a part of byte stream.
 */
void grainLengthedArray(C, T)(auto ref C cereal, ref T[] val, long length) {
    val.length = cast(typeof(val.length))length;
    foreach(ref t; val) cereal.grain(t);
}


package void grainClassImpl(C, T)(auto ref C cereal, ref T val) @safe if(isCereal!C && is(T == class)) {
    //do base classes first or else the order is wrong
    cereal.grainBaseClasses(val);
    cereal.grainAllMembersImpl!T(val);
}

private void grainBitsT(C, T)(auto ref C cereal, ref T val, int bits) @safe if(isCereal!C) {
    uint realVal = val;
    cereal.grainBits(realVal, bits);
    val = cast(T)realVal;
}

private void grainReinterpret(C, T)(auto ref C cereal, ref T val) @trusted if(isCereal!C) {
    auto ptr = cast(CerealPtrType!T)(&val);
    cereal.grain(*ptr);
}

private void grainBaseClasses(C, T)(auto ref C cereal, ref T val) @safe if(isCereal!C && is(T == class)) {
    foreach(base; BaseTypeTuple!T) {
        cereal.grainAllMembersImpl!base(val);
    }
}


private void grainAllMembersImpl(ActualType, C, ValType)(auto ref C cereal, ref ValType val) @trusted
if(isCereal!C) {
    foreach(member; __traits(derivedMembers, ActualType)) {
        //makes sure to only serialise members that make sense, i.e. data
        enum isMemberVariable = is(typeof(() {
                                           __traits(getMember, val, member) = __traits(getMember, val, member).init;
                                       }));
        static if(isMemberVariable) {
            cereal.grainMemberWithAttr!member(val);
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
