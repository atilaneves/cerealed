module cerealed.bits;

template isBitsStruct(T) {
    static if(is(T:Bits!N, int N)) {
        enum isBitsStruct = true;
    } else {
        enum isBitsStruct = false;
    }
}

struct Bits(int N) if(N <= 32) {
    uint value;
    this(uint v) { value = v; }
    @property int bits() const pure nothrow { return N; }
}
