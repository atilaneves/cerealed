module cerealed.cerealiser;

import cerealed.cereal;
import std.traits;

class Cerealiser: Cereal {
public:

    void write(T)(T val) {
        Unqual!T lval = val;
        grain(lval);
    }

    void write(T)(const ref T val) {
        grain(val);
    }

    Cerealiser opOpAssign(string op : "~", T)(T val) {
        write(val);
        return this;
    }


protected:

    override void grainUByte(ref ubyte val) {
        addByte(val);
    }
}
