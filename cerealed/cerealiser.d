module cerealed.cerealiser;

import cerealed.cereal;

class Cerealiser: Cereal {
public:

    void write(T)(T val) {
        grain(val);
    }

    void write(T)(ref T val) {
        grain(val);
    }

    Cerealiser opBinary(T, string op)(T val) if(op == "~") {
    }


protected:

    override void grainUByte(ref ubyte val) {
    }
}
