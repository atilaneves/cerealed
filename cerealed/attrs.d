module cerealed.attrs;


import std.typetuple;


template getNumBits(T) {
    static if(is(T:Bits!N, int N)) {
        enum getNumBits = N;
    } else {
        enum getNumBits = 0;
    }
}

template isABitsStruct(T) {
    static if(is(T:Bits!N, int N)) {
        enum isABitsStruct = true;
    } else {
        enum isABitsStruct = false;
    }
}


struct Bits(int N) if(N > 0 && N <= 32) {
}

enum NoCereal;
