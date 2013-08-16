module cerealed.cereal;

import std.traits;
import std.conv;

class Cereal {
public:

    //catch all signed numbers and forward to reinterpret
    void grain(T)(ref T val) if(isSigned!T || isBoolean!T || is(T == char) || isFloatingPoint!T) {
        grainReinterpret(val);
    }

    void grain(T)(ref T val) if(is(T == ubyte)) {
        grainUByte(val);
    }

    void grain(T)(ref T val) if(is(T == ushort)) {
        ubyte valh = (val >> 8);
        ubyte vall = val & 0xff;
        grainUByte(valh);
        grainUByte(vall);
        val = (valh << 8) + vall;
    }

    void grain(T)(ref T val) if(is(T == uint)) {
        ubyte val0 = (val >> 24);
        ubyte val1 = cast(ubyte)(val >> 16);
        ubyte val2 = cast(ubyte)(val >> 8);
        ubyte val3 = val & 0xff;
        grainUByte(val0);
        grainUByte(val1);
        grainUByte(val2);
        grainUByte(val3);
        val = (val0 << 24) + (val1 << 16) + (val2 << 8) + val3;
    }

    void grain(T)(ref T val) if(is(T == ulong)) {
        immutable oldVal = val;
        val = 0;

        for(int i = T.sizeof - 1; i >= 0; --i) {
            immutable shift = (T.sizeof - i) * 8;
            ubyte byteVal = (oldVal >> shift) & 0xff;
            grainUByte(byteVal);
            val |= cast(T)byteVal << shift;
        }
    }

    void grain(T)(ref T val) if(is(T == wchar)) {
        grain(*cast(ushort*)&val);
    }

    void grain(T)(ref T val) if(is(T == dchar)) {
        grain(*cast(uint*)&val);
    }

    void grain(T, U = ushort)(ref T val) if(isArray!T && !is(T == string)) {
        U length = cast(U)val.length;
        grain(length);
        if(val.length == 0) { //decoding
            val.length = length;
        }
        foreach(ref e; val) grain(e);
    }

    void grain(T, U = ushort)(ref T val) if(is(T == string)) {
        U length = cast(U)val.length;
        grain(length);
        auto values = new char[length];
        foreach(ref e; values) grain(e);
        val = cast(string)values;
    }

    void grain(T, U = ushort)(ref T val) if(isAssociativeArray!T) {
        U length = cast(U)val.length;
        grain(length);
        foreach(k, v; val) {
            grain(k);
            grain(v);
        }
    }

    void grain(T)(ref T val) if(isAggregateType!T) {
        foreach(member; __traits(allMembers, T)) {
            static if(isField(member)) {
                mixin(q{grain(val.} ~ member ~ q{);});
            }
        }
    }

    @property const(ubyte[]) bytes() const nothrow {
        return _bytes;
    }

protected:

    abstract void grainUByte(ref ubyte val);
    ubyte[] _bytes;

private:

    void grainReinterpret(T)(ref T val) {
        auto ptr = cast(CerealPtrType!T)(&val);
        grain(*ptr);
    }
}

private template CerealPtrType(T) {
    static if(is(T == bool) || is(T == char)) {
        alias ubyte* CerealPtrType;
    } else static if(is(T == float)) {
        alias uint* CerealPtrType;
    } else static if(is(T == double)) {
        alias ulong* CerealPtrType;
    } else {
       import std.traits;
       alias Unsigned!T* CerealPtrType;
    }
}

private bool isField(in string member) pure nothrow {
    return member.length < 2 || member[0..2] != "__";
}

unittest {
    static assert(isField("foo"));
    static assert(isField("_"));
    static assert(!isField("__"));
    static assert(!isField("__f"));
    static assert(!isField("__xopEquals"));
}
