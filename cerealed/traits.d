module cerealed.traits;

import cerealed.cereal;

enum isCereal(T) = is(typeof((inout int = 0) {
        ubyte b;
        auto cereal = T();
        cereal.grainUByte(b);
        uint val;
        cereal.grainBits(val, 3);
        static class Widget{}
        bool child = cereal.grainChildClass(new Widget);
        CerealType type = cereal.type;
    }));


enum isInputCereal(T) = isCereal!T && T.type == CerealType.WriteBytes;
enum isOutputCereal(T)  = isCereal!T && T.type == CerealType.ReadBytes;
