module cerealed.cereal;

class Cereal {
public:

    void grain(ref bool val) {
        grainReinterpret(val);
    }

    void grain(ref byte val) {
        grainReinterpret(val);
    }

    void grain(ref ubyte val) {
        grainUByte(val);
    }

    void grain(ref short val) {
        grainReinterpret(val);
    }

    void grain(ref ushort val) {
        ubyte valh = (val >> 8);
        ubyte vall = val & 0xff;
        grainUByte(valh);
        grainUByte(vall);
        val = (valh << 8) + vall;
    }

    void grain(ref int val) {
        grainReinterpret(val);
    }

    void grain(ref uint val) {
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

    @property const(ubyte[]) bytes() const nothrow {
        return _bytes;
    }

protected:

    ubyte[] _bytes;

    abstract void grainUByte(ref ubyte val);

private:

    void grainReinterpret(T)(ref T val) {
        auto ptr = cast(CerealPtrType!T)(&val);
        grain(*ptr);
    }
}

private template CerealPtrType(T) {
    static if(is(T == bool)) {
        alias ubyte* CerealPtrType;
    }
    else static if(is(T == double)) {
       alias ulong* CerealPtrType;
    } else {
       import std.traits;
       alias Unsigned!T* CerealPtrType;
    }
}
