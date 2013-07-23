module cerealed.cerealiser;

class Cerealiser {
    void grain(bool b) {
    }

    void grain(byte b) {
    }

    @property const(ubyte[]) bytes() const nothrow {
        return _bytes;
    }

private:

    ubyte[] _bytes;
}
