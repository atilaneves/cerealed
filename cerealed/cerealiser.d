module cerealed.cerealiser;


public import cerealed.cereal;
public import cerealed.attrs;
public import cerealed.traits;
import std.traits;
import std.exception;
import std.conv;
import std.range;
import std.array;

alias Cerealiser = CerealiserRange!(ubyte[]);

struct CerealiserRange(R) if(isOutputRange!(R, ubyte)) {
    //interface
    enum type = CerealType.WriteBytes;

    void grainUByte(ref ubyte val) @safe {
        _bytes ~= val;
    }

    void grainBits(ref uint value, int bits) @safe {
        writeBits(value, bits);
    }

    void grainClass(T)(T val) @trusted if(is(T == class)) {
        if(val.classinfo.name in _childCerealisers) {
            _childCerealisers[val.classinfo.name](this, val);
        } else {
            grainClassImpl(this, val);
        }
    }

    //specific:
    const(ubyte[]) bytes() const nothrow @property @safe {
        return _bytes.toArray();
    }

    ref CerealiserRange opOpAssign(string op : "~", T)(T val) @safe {
        write(val);
        return this;
    }

    void write(T)(T val) @safe if(!isArray!T && !isAssociativeArray!T) {
        Unqual!T lval = val;
        grain(this, lval);
    }

    void write(T)(const ref T val) @safe if(!isArray!T &&
                                            !isAssociativeArray!T &&
                                            !isAggregateType!T) {
        T lval = val;
        grain(this, lval);
    }

    void write(T)(const(T)[] val) @safe {
        T[] lval = val.dup;
        grain(this, lval);
    }

    void write(K, V)(const(V[K]) val) @trusted {
        auto lval = cast(V[K])val.dup;
        grain(this, lval);
    }

    void writeBits(in int value, in int bits) @safe {
        enforce(value < (1 << bits), text("value ", value, " too big for ", bits, " bits"));
        enum bitsInByte = 8;
        if(_bitIndex + bits >= bitsInByte) { //carries over to next byte
            const remainingBits = _bitIndex + bits - bitsInByte;
            const thisByteValue = (value >> remainingBits);
            _currentByte |= thisByteValue;
            grainUByte(_currentByte);
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

    void reset() @trusted {
        if(_bytes !is null) {
            _bytes = _bytes[0..0];
            _bytes.assumeSafeAppend();
        }
    }

    static void registerChildClass(T)() @safe {
        _childCerealisers[T.classinfo.name] = (ref Cerealiser cereal, Object val) {
            T child = cast(T)val;
            cereal.grainClassImpl(child);
        };
    }

private:

    R _bytes;
    ubyte _currentByte;
    int _bitIndex;
    static void function(ref CerealiserRange cereal, Object val)[string] _childCerealisers;

    static assert(isCereal!CerealiserRange);
    static assert(isCerealiser!CerealiserRange);
}


private const(ubyte[]) toArray(T)(T val) nothrow pure @safe {
    static if(isArray!T) {
        return val;
    } else {
        return val.array;
    }
}
