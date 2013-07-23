module cerealed.cereal;

class Cereal {
public:

    void grain(ref bool val) {
    }


    void grain(ref byte bal) {
    }

    @property const(ubyte[]) bytes() const nothrow {
        return _bytes;
    }

protected:

    ubyte[] _bytes;

    abstract void grainUByte(ref ubyte val);
}
