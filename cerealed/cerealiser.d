module cerealed.cerealiser;

import cerealed.cereal;

class Cerealiser: Cereal {
public:

    void write(T)(T val) {
        grain(val);
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
