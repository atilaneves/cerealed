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

/**
 Exclude this member from serialization
 */
enum NoCereal;


/**
 Do not encode array length before the array.
 This consumes the remaining bytes when deserializing
 */
enum RawArray;
alias RestOfPacket = RawArray;
alias Rest = RawArray;


/**
 Inform the library about which member variable contains
 the length for an array measured in number of elements, not bytes
 */
struct ArrayLength {
    string member;
}


enum isArrayLengthStruct(alias T) = is(typeof(T)) && is(typeof(T) == ArrayLength);

unittest {
    auto l = ArrayLength();
    static assert(isArrayLengthStruct!l);
}

/**
 Specifies the length of an array by the number of bytes, not elements
 */
struct LengthInBytes {
    string member;
}


enum isLengthInBytesStruct(alias T) = is(typeof(T)) && is(typeof(T) == LengthInBytes);

unittest {
    auto l = LengthInBytes();
    static assert(isLengthInBytesStruct!l);
}


struct LengthType(T) {
    alias Type = T;
}
enum isLengthType(alias T) = is(T) && is(T:LengthType!U, U);

unittest {
    static assert(isLengthType!(LengthType!ushort));
}
