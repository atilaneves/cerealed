module cerealed.bits;

import std.traits;

template isBitsStruct(T) {
    static if(hasMember!(T, "_BitsSecretMember")) {
        enum isBitsStruct = true;
    } else {
        enum isBitsStruct = false;
    }
}

struct Bits(int N) if(N <= 32) {
    enum _BitsSecretMember;
    @property int bits() { return N; }
    uint value;
}
