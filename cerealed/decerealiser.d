module cerealed.decerealiser;

public import cerealed.cereal;
public import cerealed.attrs;
public import cerealed.traits;
import std.traits;


struct Decerealiser {
    //interface:
    enum type = CerealType.ReadBytes;

    void grainUByte(ref ubyte val) @safe {
        val = _bytes[0];
        _bytes = _bytes[1..$];
    }

    void grainBits(ref uint value, int bits) @safe {
        value = readBits(bits);
    }

    bool grainChildClass(Object val) @safe {
        return false;
    }

    //specific:
    this(T)(in T[] bytes) @safe if(isNumeric!T) {
        setBytes(bytes);
    }

    const(ubyte[]) bytes() const nothrow @property @safe {
        return _bytes;
    }

    ulong bytesLeft() const @safe { return bytes.length; }

    @property @safe final T value(T)() if(!isArray!T && !isAssociativeArray!T &&
                                          !is(T == class)) {
        T val;
        grain(this, val);
        return val;
    }

    @property @trusted final T value(T, A...)(A args) if(is(T == class)) {
        auto val = new T(args);
        grain(this, val);
        return val;
    }

    @property @safe final T value(T, U = short)() if(isArray!T || isAssociativeArray!T) {
        T val;
        grain!(typeof(this), T, U)(this, val);
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

    final uint readBits(int bits) @safe {
        if(_bitIndex == 0) {
            _currentByte = this.value!ubyte;
        }

        return readBitsHelper(bits);
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

    final void setBytes(T)(in T[] bytes) @trusted if(isNumeric!T) {
        static if(is(T == ubyte)) {
            _bytes = bytes;
        } else {
            foreach(b; bytes) _bytes ~= cast(ubyte)b;
        }

        _originalBytes = _bytes;
    }

    static assert(isCereal!Decerealiser);
    static assert(isOutputCereal!Decerealiser);
}


class OldDecerealiser: CerealT!OldDecerealiser {
public:

    final CerealType type() const pure nothrow @safe { return CerealType.ReadBytes; }
    final ulong bytesLeft() const @safe { return bytes.length; }

    final void grainUByte(ref ubyte val) @safe {
        val = _bytes[0];
        _bytes = _bytes[1..$];
    }

    final void grainBits(ref uint value, int bits) @safe {
        value = readBits(bits);
    }

    final bool grainChildClass(Object val) @trusted {
        return false;
    }

    this() @safe {
        static const ubyte[] empty;
        this(empty);
    }

    this(T)(in T[] bytes) @safe if(isNumeric!T) {
        super(this);
        setBytes(bytes);
    }

    @property @safe final T value(T)() if(!isArray!T && !isAssociativeArray!T &&
                                          !is(T == class)) {
        T val;
        grain(val);
        return val;
    }

    @property @trusted final T value(T, A...)(A args) if(is(T == class)) {
        auto val = new T(args);
        grain(val);
        return val;
    }

    @property @safe final T value(T, U = short)() if(isArray!T || isAssociativeArray!T) {
        T val;
        grain!(T, U)(val);
        return val;
    }

    alias read = grain;

    final const(ubyte[]) bytes() const nothrow @safe @property {
        return _bytes;
    }

    final uint readBits(int bits) @safe {
        if(_bitIndex == 0) {
            _currentByte = this.value!ubyte;
        }

        return readBitsHelper(bits);
    }

    final void reset() @safe {
        /**resets the decerealiser to read from the beginning again*/
        reset(_originalBytes);
    }

    final void reset(T)(in T[] bytes) @safe if(isNumeric!T) {
        /**resets the decerealiser to use the new slice*/
        _bitIndex = 0;
        _currentByte = 0;
        setBytes(bytes);
    }

private:

    const (ubyte)[] _originalBytes;
    const (ubyte)[] _bytes;
    ubyte _currentByte;
    int _bitIndex;

    final uint readBitsHelper(int bits) @safe {
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

    final void setBytes(T)(in T[] bytes) @trusted if(isNumeric!T) {
        static if(is(T == ubyte)) {
            _bytes = bytes;
        } else {
            foreach(b; bytes) _bytes ~= cast(ubyte)b;
        }

        _originalBytes = _bytes;
    }
}
