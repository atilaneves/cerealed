module cerealed.bits;

template isBitsStruct(T) {
    static if(is(T:Bits!N, int N)) {
        enum isBitsStruct = true;
    } else {
        enum isBitsStruct = false;
    }
}

struct Bits(int N) if(N <= 32) {
    @property int bits() { return N; }
    uint value;
}
