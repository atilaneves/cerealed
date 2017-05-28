module cerealed.decerealiser;

import cerealed.cereal: grain;
import cerealed.traits: isCereal, isDecerealiser;
import concepts: models;

auto decerealise(T)(in ubyte[] bytes) @trusted {
    return Decerealiser(bytes).value!T;
}

@models!(Decerealiser, isCereal)
@models!(Decerealiser, isDecerealiser)
struct Decerealiser {

    import cerealed.cereal: CerealType;
    import std.traits: isNumeric, isDynamicArray, isAssociativeArray;

    //interface:
    enum type = CerealType.ReadBytes;

    void grainUByte(ref ubyte val) @safe {
        val = _bytes[0];
        _bytes = _bytes[1..$];
    }

    void grainBits(ref uint value, int bits) @safe {
        value = readBits(bits);
    }

    void grainClass(T)(T val) @trusted if(is(T == class)) {
        import cerealed.cereal: grainClassImpl;
        grainClassImpl(this, val);
    }

    auto grainRaw(size_t length) @safe {
        auto res = _bytes[0..length];
        _bytes = _bytes[length..$];
        return res;
    }

    //specific:
    this(T)(in T[] bytes) @safe if(isNumeric!T) {
        setBytes(bytes);
    }

    const(ubyte[]) bytes() const nothrow @property @safe {
        return _bytes;
    }

    ulong bytesLeft() const @safe { return bytes.length; }

    @property T value(T)() if(!isDynamicArray!T && !isAssociativeArray!T &&
                              !is(T == class) && __traits(compiles, T())) {
        T val;
        grain(this, val);
        return val;
    }

    @property T value(T)() if(!isDynamicArray!T && !isAssociativeArray!T &&
                              !is(T == class) && !__traits(compiles, T())) {
        T val = void;
        grain(this, val);
        return val;
    }

    @property @trusted T value(T, A...)(A args) if(is(T == class)) {
        auto val = new T(args);
        grain(this, val);
        return val;
    }

    @property @safe T value(T)() if(isDynamicArray!T || isAssociativeArray!T) {
        return value!(T, ushort)();
    }

    @property @safe T value(T, U)() if(isDynamicArray!T || isAssociativeArray!T) {
        T val;
        grain!U(this, val);
        return val;
    }


    void reset() @safe {
        /**resets the decerealiser to read from the beginning again*/
        reset(_originalBytes);
    }

    void reset(T)(in T[] bytes) @safe if(isNumeric!T) {
        /**resets the decerealiser to use the new slice*/
        _bitIndex = 0;
        _currentByte = 0;
        setBytes(bytes);
    }

    void read(T)(ref T val) @trusted {
        grain(this, val);
    }

    uint readBits(int bits) @safe {
        if(_bitIndex == 0) {
            _currentByte = this.value!ubyte;
        }

        return readBitsHelper(bits);
    }

    const(ubyte)[] originalBytes() @safe pure nothrow const {
        return _originalBytes;
    }

private:

    const (ubyte)[] _originalBytes;
    const (ubyte)[] _bytes;
    ubyte _currentByte;
    int _bitIndex;

    uint readBitsHelper(int bits) @safe {
        enum bitsInByte = 8;
        if(_bitIndex + bits > bitsInByte) { //have to carry on to the next byte
            immutable bits1stTime = bitsInByte - _bitIndex; //what's left of this byte
            immutable bits2ndTime = (_bitIndex + bits) - bitsInByte; //bits to read from next byte
            immutable value1 = readBitsHelper(bits1stTime);
            _bitIndex = 0;
            _currentByte = this.value!ubyte;
            immutable value2 = readBitsHelper(bits2ndTime);
            return (value1 << bits2ndTime) | value2;
        }

        _bitIndex += bits;

        auto shift =  _currentByte >> (bitsInByte - _bitIndex);
        return shift & (0xff >> (bitsInByte - bits));
    }

    void setBytes(T)(in T[] bytes) @trusted if(isNumeric!T) {
        static if(is(T == ubyte)) {
            _bytes = bytes;
        } else {
            foreach(b; bytes) _bytes ~= cast(ubyte)b;
        }

        _originalBytes = _bytes;
    }

    // static assert(isCereal!Decerealiser);
    // static assert(isDecerealiser!Decerealiser);
}
