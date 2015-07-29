module cerealed.utils;

import std.traits;

int unalignedSizeof(T)() {
    static if(!isAggregateType!T || is(T == union)) {
        return T.sizeof;
    } else {
        int size;
        foreach(member; T().tupleof) {
            size += unalignedSizeof!(typeof(member));
        }
        return size;
    }
}
