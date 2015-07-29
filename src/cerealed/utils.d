module cerealed.utils;

import std.traits;

int unalignedSizeof(T)() {
    T initValue() {
        static if(is(T == class))
            return new T;
        else
            return T.init;
    }

    static if(!isAggregateType!T || is(T == union)) {
        return T.sizeof;
    } else {
        int size;
        foreach(member; initValue.tupleof) {
            size += unalignedSizeof!(typeof(member));
        }
        return size;
    }
}
