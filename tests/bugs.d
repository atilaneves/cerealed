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
    checkEqual(enc.bytes, [0, 1, 0, 3, 'f', 'o', 'o', 0, 0, 0, 5, 0, 0, 0, 105]);

    auto dec = Decerealiser(enc.bytes);
    auto map2 = dec.value!(int[Pair]);

    checkEqual(map.keys, map2.keys);
    checkEqual(map.values, map2.values);
}
