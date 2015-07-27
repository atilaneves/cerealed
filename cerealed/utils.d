module cerealed.utils;

int unalignedSizeof(T)() {
    int size;
    foreach(member; T().tupleof) {
        size += member.sizeof;
    }
    return size;
}
