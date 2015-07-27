module tests.protocol_unit;


import cerealed;
import unit_threaded;
import core.exception;


struct Unit {
    ushort us;
    ubyte ub1;
    ubyte ub2;
}

struct Packet {
    ubyte ub1;
    ushort length;
    ubyte ub2;
    @Length("length") Unit[] units;
}


void testUnits() {
    ubyte[] bytes = [3, 0, 4, 9, 0, 7, 1, 2, 0, 6, 2, 3, 0, 5, 4, 5, 0, 4, 9, 8];
    auto dec = Decerealiser(bytes);
    auto pkt = dec.value!Packet;
    dec.value!ubyte.shouldThrow!RangeError; //no more bytes

    pkt.ub1.shouldEqual(3);
    pkt.length.shouldEqual(4);
    pkt.ub2.shouldEqual(9);
    pkt.units.length.shouldEqual(pkt.length);

    pkt.units[1].us.shouldEqual(6);
    pkt.units[1].ub1.shouldEqual(2);
    pkt.units[1].ub2.shouldEqual(3);

    auto enc = Cerealiser();
    enc ~= pkt;
    enc.bytes.shouldEqual(bytes);
}
