module cerealed.cerealiser;

import cerealed.cereal;
public import cerealed.bits;
import std.traits;
import std.exception;
import std.conv;


class Cerealiser: Cereal {
public:

    void write(T)(T val) if(!isArray!T && !isAssociativeArray!T) {
        Unqual!T lval = val;
        grain(lval);
    }

    void write(T)(const(T)[] val) {
        T[] lval = val.dup;
        grain(lval);
    }

    void write(K, V)(const(V[K]) val) {
        V[K] lval = cast(V[K])val.dup;
        grain(lval);
    }

    void write(T)(const ref T val) if(!isArray!T && !isAssociativeArray!T &&
                                      !isAggregateType!T) {
        T realVal = val;
        grain(realVal);
    }

    void writeBits(in int value, in int bits) {
        enforce(value < (1 << bits), text("value ", value, " too big for ", bits, " bits"));
        enum bitsInByte = 8;
        if(_bitIndex + bits >= bitsInByte) { //carries over to next byte
            const remainingBits = _bitIndex + bits - bitsInByte;
            const thisByteValue = (value >> remainingBits);
            _currentByte |= thisByteValue;
            this ~= _currentByte;
            _currentByte = 0;
            _bitIndex = 0;
            if(remainingBits > 0) {
                ubyte remainingValue = value & (0xff >> (bitsInByte - remainingBits));
                writeBits(remainingValue, remainingBits);
            }
            return;
        }
        _currentByte |= (value << (bitsInByte - bits - _bitIndex));
        _bitIndex += bits;
    }

    Cerealiser opOpAssign(string op : "~", T)(T val) {
        write(val);
        return this;
    }

    @property const(ubyte[]) bytes() const nothrow {
        return _bytes;
    }

protected:

    override void grainUByte(ref ubyte val) {
        _bytes ~= val;
    }

    override void grainBits(ref uint value, int bits) {
        writeBits(value, bits);
    }


private:

    ubyte[] _bytes;
    ubyte _currentByte;
    int _bitIndex;
}
