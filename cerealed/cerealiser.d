module cerealed.cerealiser;


import cerealed.cereal;
public import cerealed.attrs;
import std.traits;
import std.exception;
import std.conv;
import std.range;


class Cerealiser: Cereal {
public:

    override Type type() const pure nothrow @safe { return Cereal.Type.Write; }
    override ulong bytesLeft() const @safe { return bytes.length; }

    final void write(T)(const ref T val) @safe if(!isArray!T &&
                                                  !isAssociativeArray!T &&
                                                  !isAggregateType!T) {
        T realVal = val;
        grain(realVal);
    }

    final void write(T)(T val) @safe if(!isArray!T && !isAssociativeArray!T && !isInputRange!T) {
        Unqual!T lval = val;
        grain(lval);
    }

    final void write(T)(const(T)[] val) @safe {
        T[] lval = val.dup;
        grain(lval);
    }

    final void write(K, V)(const(V[K]) val) @trusted {
        auto lval = cast(V[K])val.dup;
        grain(lval);
    }

    final void write(R, U = ushort)(R val) @trusted if(isInputRange!R && !isInfinite!R && !isArray!R) {
        U length = cast(U)val.length;
        grain(length);
        foreach(ref e; val) grain(e);
    }

    final void writeBits(in int value, in int bits) @safe {
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

    final Cerealiser opOpAssign(string op : "~", T)(T val) @safe {
        write(val);
        return this;
    }

    final const(ubyte[]) bytes() const nothrow @property @safe {
        return _bytes;
    }

    final void reset() @trusted {
        if(_bytes !is null) {
            _bytes = _bytes[0..0];
            _bytes.assumeSafeAppend();
        }
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
