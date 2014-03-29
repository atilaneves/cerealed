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


enum isCerealiser(T) = isCereal!T && T.type == CerealType.WriteBytes;
enum isDecerealiser(T) = isCereal!T && T.type == CerealType.ReadBytes &&
    is(typeof((inout int = 0) { auto dec = T(); ulong bl = dec.bytesLeft; }));


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



mixin template assertHasPostBlit(T) {
    static if(!hasPostBlit!T) {
        void func(inout int = 0) {
            auto obj = T.init;
            auto enc = Cerealiser();
            obj.postBlit(enc);
            auto dec = Decerealiser();
            obj.postBlit(dec);
        }
    }
}


mixin template assertHasAccept(T) {
    static if(!hasAccept!T) {
        void func(inout int = 0) {
            auto obj = T.init;
            auto enc = Cerealiser();
            obj.accept(enc);
            auto dec = Decerealiser();
            obj.accept(dec);
        }
    }
}
