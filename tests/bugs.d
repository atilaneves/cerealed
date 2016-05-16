module tests.bugs;

import unit_threaded;
import cerealed;


private struct Pair {
  string s;
  int i;
}


void testAssocArrayWithPair() {
    auto p = Pair("foo", 5);
    auto map = [p: 105];
    auto enc = Cerealiser();

    enc ~= map;
    enc.bytes.shouldEqual([0, 1, 0, 3, 'f', 'o', 'o', 0, 0, 0, 5, 0, 0, 0, 105]);

    auto dec = Decerealiser(enc.bytes);
    auto map2 = dec.value!(int[Pair]);

    map.keys.shouldEqual(map2.keys);
    map.values.shouldEqual(map2.values);
}

void testByteArray() {
    ubyte[] arr = [1,2,3,4];

    auto enc = Cerealiser();
    enc ~= arr;

    auto dec = Decerealiser(enc.bytes);
    auto arr2 = dec.value!(ubyte[]);

    arr.shouldEqual(arr2);
}


@("bool array")
unittest {
    auto arr = [true, false, true];
    auto enc = Cerealiser();
    enc ~= arr;
    enc.bytes.shouldEqual([0, 3, 1, 0, 1]);

    auto dec = Decerealiser(enc.bytes);
    dec.value!(bool[]).shouldEqual(arr);
}
