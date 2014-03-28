module cerealed.cerealiser;


import cerealed.cereal;
import cerealed.traits;
public import cerealed.attrs;
import std.traits;
import std.exception;
import std.conv;

struct Cerealiser {
    //interface
    CerealType type() const pure nothrow @safe {
        return CerealType.Write;
    }

    void grainUByte(ref ubyte val) @safe {
        _bytes ~= val;
    }

    void grainBits(ref uint value, int bits) @safe {
    }

    bool grainChildClass(Object val) @safe {
        return true;
    }

    //specific
    const(ubyte[]) bytes() const nothrow @property @safe {
        return _bytes;
    }

    ref Cerealiser opOpAssign(string op : "~", T)(T val) @safe {
        write(val);
        return this;
    }

    void write(T)(auto ref T val) @safe {
        this.grain(val);
    }

private:

    ubyte[] _bytes;

    static assert(isCereal!Cerealiser);
}

class OldCerealiser: CerealT!OldCerealiser {
public:

    this() {
        super(this);
    }

    final CerealType type() const pure nothrow @safe { return CerealType.Write; }
    final ulong bytesLeft() const @safe { return bytes.length; }

    final void grainUByte(ref ubyte val) @safe {
        _bytes ~= val;
    }

    final void grainBits(ref uint value, int bits) @safe {
        writeBits(value, bits);
    }

    final bool grainChildClass(Object val) @trusted {
        if(val.classinfo.name !in _childOldCerealisers) return false;
        _childOldCerealisers[val.classinfo.name](this, val);
        return true;
    }

    final void write(T)(const ref T val) @safe if(!isArray!T &&
                                                  !isAssociativeArray!T &&
                                                  !isAggregateType!T) {
        T realVal = val;
        grain(realVal);
    }

    final void write(T)(T val) @safe if(!isArray!T && !isAssociativeArray!T) {
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

    final OldCerealiser opOpAssign(string op : "~", T)(T val) @safe {
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

    static void registerChildClass(T)() @safe {
        _childOldCerealisers[T.classinfo.name] = (OldCerealiser cereal, Object val){
            T child = cast(T)val;
            cereal.grainClassImpl(child);
        };
    }

private:

    ubyte[] _bytes;
    ubyte _currentByte;
    int _bitIndex;
    static void function(OldCerealiser cereal, Object val)[string] _childOldCerealisers;
}
