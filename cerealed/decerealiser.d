module cerealed.decerealiser;

import cerealed.cereal;
public import cerealed.attrs;
import std.traits;

class Decerealiser: Cereal {
public:

    override Type type() const { return Cereal.Type.Read; }

    this(T)(in T[] bytes) if(isNumeric!T) {
        static if(is(T == ubyte)) {
            _bytes = bytes;
        } else {
            foreach(b; bytes) _bytes ~= cast(ubyte)b;
        }

        _originalBytes = _bytes;
    }

    @property T value(T)() if(!isArray!T && !isAssociativeArray!T) {
        T val;
        grain(val);
        return val;
    }

    @property T value(T, U = short)() if(isArray!T || isAssociativeArray!T) {
        T val;
        grain!(T, U)(val);
        return val;
    }

    @property const(ubyte[]) bytes() const nothrow {
        return _bytes;
    }

    uint readBits(int bits) {
        if(_bitIndex == 0) {
            _currentByte = this.value!ubyte;
        }

        return readBitsHelper(bits);
    }

    void reset() {
        /**resets the deceraliser to read from the beginning again*/
        _bitIndex = 0;
        _currentByte = 0;
        _bytes = _originalBytes;
    }

protected:

    override void grainUByte(ref ubyte val) {
        val = _bytes[0];
        _bytes = _bytes[1..$];
    }

    override void grainBits(ref uint value, int bits) {
        value = readBits(bits);
    }

private:

    const (ubyte)[] _originalBytes;
    const (ubyte)[] _bytes;
    ubyte _currentByte;
    int _bitIndex;

    uint readBitsHelper(int bits) {
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
}
