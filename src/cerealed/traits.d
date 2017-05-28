module cerealed.traits;

import cerealed.cereal;
import cerealed.cerealiser;
import cerealed.decerealiser;


void checkCereal(T)() {
    ubyte b;
    auto cereal = T.init;
    cereal.grainUByte(b);
    uint val;
    cereal.grainBits(val, 3);
    CerealType type = cereal.type;
    // can't check grainClass because it calls grainClassImpl,
    // which uses the template constraint isCereal
    // Class class_;
    // cereal.grainClass(class_);
}

enum isCereal(T) = is(typeof(checkCereal!T));

void checkCerealiser(T)() {
    checkCereal!T;
    static assert(T.type == CerealType.WriteBytes);
}

enum isCerealiser(T) = is(typeof(checkCerealiser!T));

void checkDecerealiser(T)() {
    checkCereal!T;
    static assert(T.type == CerealType.ReadBytes);
    auto dec = T();
    ulong bl = dec.bytesLeft;
}

enum isDecerealiser(T) = is(typeof(checkDecerealiser!T));


bool hasFunc(T, string funcName)() {
    if(!__ctfe) {
        auto obj = T.init;
        auto enc = Cerealiser();
        mixin("obj." ~ funcName ~ "(enc);");
        auto dec = Decerealiser();
        mixin("obj." ~ funcName ~ "(dec);");
    }
    return true;
}

enum hasAccept(T)   = hasFunc!(T, "accept");
enum hasPostBlit(T) = hasFunc!(T, "postBlit");
enum hasPreBlit(T)  = hasFunc!(T, "preBlit");

unittest {
    struct Accept {
        void accept(C)(auto ref C cereal) if(isCereal!C) { }
    }

    static assert(hasAccept!Accept);
}

mixin template assertHas(T, string funcName) {
    static assert(hasFunc!(T, funcName));
}

mixin template assertHasPostBlit(T) { mixin assertHas!(T, "postBlit"); }
mixin template assertHasPreBlit(T)  { mixin assertHas!(T, "preBlit"); }
mixin template assertHasAccept(T)   { mixin assertHas!(T, "accept"); }

private class Class { ubyte ub; }
