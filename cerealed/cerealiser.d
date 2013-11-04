module cerealed.cerealiser;

import cerealed.cereal;
import std.traits;


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

    void writeBits(ubyte value, int bits) {
        enum bitsInByte = 8;
        _currentByte |= (value << (bitsInByte - bits - _bitIndex));
        _bitIndex += bits;
        if(_bitIndex == bitsInByte) {
            this ~= _currentByte;
            _bitIndex = 0;
            _currentByte = 0;
        }
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

private:

    ubyte[] _bytes;
    ubyte _currentByte;
    int _bitIndex;
}
