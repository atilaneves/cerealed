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

    @property const(ubyte[]) bytes() const nothrow {
        return _bytes;
    }

protected:

    ubyte[] _bytes;

    abstract void grainUByte(ref ubyte val);

private:

    void grainReinterpret(T)(ref T val) {
        auto ptr = cast(CerealTraits!T)(&val);
        grain(*ptr);
    }
}

private template CerealTraits(T) {
    static if(is(T == bool)) {
        alias ubyte* CerealTraits;
    } else {
        alias ubyte* CerealTraits;
    }
}
