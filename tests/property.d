module tests.property;

import cerealed;
import unit_threaded;


@Types!(bool, byte, ubyte, short, ushort, int, uint, long, ulong,
        float, double,
        char, wchar, dchar,
        ubyte[], ushort[], int[], long[], float[], double[])
void testEncodeDecodeProperty(T)() @safe {
    check!((T val) => val.cerealise.decerealise!T == val);
}


@("array with non-default length type")
@safe unittest {
    check!((ubyte[] arr) {
        if(arr.length > ubyte.max) {
            return true;
        }
        auto enc = Cerealiser();
        enc.grain!ubyte(arr);
        enc.bytes.length.shouldEqual(arr.length + ubyte.sizeof);
        auto dec = Decerealiser(enc.bytes);
        ubyte[] arr2;
        dec.grain!ubyte(arr2);
        return arr2 == arr;
    });
}
