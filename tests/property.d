module tests.property;

import cerealed;
import unit_threaded;


@Types!(bool, byte, ubyte, short, ushort, int, uint, long, ulong,
        float, double,
        char, wchar, dchar,
        ubyte[], ushort[], int[])
void testEncodeDecodeProperty(T)() {
    check!((T val) {
        auto enc = Cerealiser();
        enc ~= val;
        auto dec = Decerealiser(enc.bytes);
        return dec.value!T == val;
    });
}


@("array with non-default length type")
unittest {
    check!((ubyte[] arr) {
        if(arr.length > ubyte.max) {
            return true;
        }
        auto enc = Cerealiser();
        enc.grain!ubyte(arr);
        auto dec = Decerealiser(enc.bytes);
        ubyte[] arr2;
        dec.grain!ubyte(arr2);
        return arr2 == arr;
    });
}
