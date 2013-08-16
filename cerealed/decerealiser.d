module cerealed.decerealiser;

import cerealed.cereal;
import std.traits;

class Decerealiser: Cereal {
public:

    this(T)(T[] bytes) if(isNumeric!T) {
        static if(is(T == ubyte)) {
            _bytes = bytes.dup;
        } else {
            foreach(b; bytes) _bytes ~= cast(ubyte)b;
        }
    }

    @property T value(T)() if(!isArray!T && !isAssociativeArray!T) {
        T val;
        grain(val);
        return val;
    }

    @property T value(T, U = short)() if(isArray!T || isAssociativeArray!T) {
        T val;
        grain!(T, U)(val);
        return val;
    }

protected:

    override void grainUByte(ref ubyte val) {
        val = _bytes[0];
        _bytes = _bytes[1..$];
    }
}
