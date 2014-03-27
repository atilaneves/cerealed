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
        ulong left = cereal.bytesLeft();
        CerealType type = cereal.type();
    }));
