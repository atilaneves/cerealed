module cerealed.attrs;


import std.typetuple;


template getNumBits(T) {
    static if(is(T:Bits!N, int N)) {
        enum getNumBits = N;
    } else {
        enum getNumBits = 0;
    }
}


enum isABitsStruct(alias T) = is(T) && is(T:Bits!N, int N);


struct Bits(int N) if(N > 0 && N <= 32) {
}

enum NoCereal;
enum RawArray;

alias RestOfPacket = RawArray;

struct ArrayLength {
    string member;
}


enum isArrayLengthStruct(alias T) = is(typeof(T)) && is(typeof(T) == ArrayLength);

unittest {
    auto l = ArrayLength();
    static assert(isArrayLengthStruct!l);
}


struct LengthInBytes {
    string member;
}


enum isLengthInBytesStruct(alias T) = is(typeof(T)) && is(typeof(T) == LengthInBytes);

unittest {
    auto l = LengthInBytes();
    static assert(isLengthInBytesStruct!l);
}
