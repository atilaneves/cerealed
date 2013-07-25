module cerealed.cerealiser;

import cerealed.cereal;
import std.traits;

class Cerealiser: Cereal {
public:

    void write(T)(T val) if(!isArray!T && !isAssociativeArray!T) {
        T lval = val;
        grain(lval);
    }

    void write(T)(const(T)[] val) {
        T[] lval = val.dup;
        grain(lval);
    }

    void write(K, V)(const(V[K]) val) {
        V[K] lval = cast(V[K])val.dup;
        grain(lval);
    }

    void write(T)(const ref T val) if(!isArray!T && !isAssociativeArray!T) {
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
