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
    auto pkt = decerealise!Packet(bytes);

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


struct PacketWithTotalLength {
    enum headerSize = ub.sizeof + us.sizeof + length.sizeof;

    ubyte ub;
    ushort us;
    ushort length;
    @Length("length - headerSize") Unit[] units;
}

void testTotalLength() {
    ubyte[] bytes = [3, 0, 7, 0, 8, 0, 7, 1, 2, 0, 6, 2, 3, 0, 5, 4, 5];
    auto pkt = decerealise!PacketWithTotalLength(bytes);

    pkt.ub.shouldEqual(3);
    pkt.us.shouldEqual(7);
    pkt.units.length.shouldEqual(3);

    pkt.units[2].us.shouldEqual(5);
    pkt.units[2].ub1.shouldEqual(4);
    pkt.units[2].ub2.shouldEqual(5);
}
