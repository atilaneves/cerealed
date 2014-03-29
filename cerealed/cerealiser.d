module cerealed.cerealiser;


public import cerealed.cereal;
public import cerealed.attrs;
public import cerealed.traits;
import std.traits;
import std.exception;
import std.conv;
import std.range;
import std.array;


alias AppenderCerealiser = CerealiserImpl!(Appender!(ubyte[]));
alias DynamicArrayCerealiser = CerealiserImpl!DynamicArrayRange;
alias Cerealiser = AppenderCerealiser;


template isCerealiserRange(R) {
    enum isCerealiserRange = isOutputRange!(R, ubyte) &&
        is(typeof((inout int = 0) { auto r = R(); r.clear(); const(ubyte)[] d = r.data; }));
}


struct DynamicArrayRange {
    void put(in ubyte val) nothrow @safe {
        _bytes ~= val;
    }

    const(ubyte)[] data() pure const nothrow @property @safe {
        return _bytes;
    }

    void clear() @trusted {
        if(_bytes !is null) {
            _bytes = _bytes[0..0];
            _bytes.assumeSafeAppend();
        }
    }

private:
    ubyte[] _bytes;
    static assert(isCerealiserRange!DynamicArrayRange);
}


struct CerealiserImpl(R) if(isCerealiserRange!R) {
    //interface
    enum type = CerealType.WriteBytes;

    void grainUByte(ref ubyte val) @safe {
        _output.put(val);
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
        return _output.data;
    }

    ref CerealiserImpl opOpAssign(string op : "~", T)(T val) @safe {
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

    void reset() @safe {
        _output.clear();
    }

    static void registerChildClass(T)() @safe {
        _childCerealisers[T.classinfo.name] = (ref Cerealiser cereal, Object val) {
            T child = cast(T)val;
            cereal.grainClassImpl(child);
        };
    }

private:

    R _output;
    ubyte _currentByte;
    int _bitIndex;
    static void function(ref CerealiserImpl cereal, Object val)[string] _childCerealisers;

    static assert(isCereal!CerealiserImpl);
    static assert(isCerealiser!CerealiserImpl);
}


private const(ubyte[]) toArray(T)(T val) nothrow pure @safe {
    static if(isArray!T) {
        return val;
    }
    static if(is(typeof((inout int = 0) { return val.array; }))) {
        return val.val;
    }
    static if(is(T == Appender!(ubyte[]))) {
        return val.data;
    }
}
