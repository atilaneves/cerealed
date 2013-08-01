module cerealed.decerealiser;

import cerealed.cereal;

class Decerealiser: Cereal {
public:

    this(ubyte[] bytes) {
        _bytes = bytes.dup;
    }

protected:

    override void grainUByte(ref ubyte val) {
        val = _bytes[0];
        _bytes = _bytes[1..$];
    }
}
