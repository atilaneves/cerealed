module cerealed.traits;

import cerealed.cereal;
import cerealed.cerealiser;
import cerealed.decerealiser;


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


enum hasAccept(T) = is(typeof((inout int = 0) {
            auto obj = T.init;
            auto enc = Cerealiser();
            obj.accept(enc);
            auto dec = Decerealiser();
            obj.accept(dec);
}));


enum hasPostBlit(T) = is(typeof((inout int = 0) {
            auto obj = T.init;
            auto enc = Cerealiser();
            obj.postBlit(enc);
            auto dec = Decerealiser();
            obj.postBlit(dec);
}));
