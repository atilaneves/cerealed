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

    @property int[] value(T)() if(isArray!T) {
        ushort length;
        grain(length);
        T values;
        values.length = length; //allocate, can't use new
        for(ushort i = 0; i < length; ++i) {
            grain(values[i]);
        }
        return values;
    }


    @property T value(T, U = ushort)() if(isAssociativeArray!T) {
        T val;
        grain(val);
        return val;
    }


protected:

    override void grainUByte(ref ubyte val) {
        val = _bytes[0];
        _bytes = _bytes[1..$];
    }
}
