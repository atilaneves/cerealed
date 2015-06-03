module cerealed.attrs;


import std.typetuple;


template getNumBits(T) {
    static if(is(T:Bits!N, int N)) {
        enum getNumBits = N;
    } else {
        enum getNumBits = 0;
    }
}


enum isABitsStruct(T) = is(T:Bits!N, int N);


struct Bits(int N) if(N > 0 && N <= 32) {
}

enum NoCereal;
enum RawArray;

alias RestOfPacket = RawArray;
