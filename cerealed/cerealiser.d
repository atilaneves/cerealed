module cerealed.cerealiser;


import cerealed.cereal;
public import cerealed.attrs;
import std.traits;
import std.exception;
import std.conv;


class Cerealiser: Cereal {
public:

    override Type type() const pure nothrow @safe { return Cereal.Type.Write; }
    override ulong bytesLeft() const @safe { return bytes.length; }

    void write(T)(const ref T val) @safe if(!isArray!T &&
                                            !isAssociativeArray!T &&
                                            !isAggregateType!T) {
        T realVal = val;
        grain(realVal);
    }

    void write(T)(T val) @safe if(!isArray!T && !isAssociativeArray!T) {
        Unqual!T lval = val;
        grain(lval);
    }

    void write(T)(const(T)[] val) @safe {
        T[] lval = val.dup;
        grain(lval);
    }

    void write(K, V)(const(V[K]) val) @trusted {
        auto lval = cast(V[K])val.dup;
        grain(lval);
    }

    void writeBits(in int value, in int bits) @safe {
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

    Cerealiser opOpAssign(string op : "~", T)(T val) @safe {
        write(val);
        return this;
    }

    const(ubyte[]) bytes() const nothrow @property @safe {
        return _bytes;
    }

    void reset() @trusted {
        _bytes = _bytes[0..0];
        _bytes.assumeSafeAppend();
    }

protected:

    override void grainUByte(ref ubyte val) @safe {
        _bytes ~= val;
    }

    override void grainBits(ref uint value, int bits) @safe {
        writeBits(value, bits);
    }


private:

    ubyte[] _bytes;
    ubyte _currentByte;
    int _bitIndex;
}
