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
    @ArrayLength("length") Unit[] units;
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


struct PacketWithArrayLengthExpr {
    static struct Header {
        ubyte ub;
        ushort us;
        ushort length;
    }

    enum headerSize = unalignedSizeof!Header;
    alias header this;

    Header header;
    @ArrayLength("length - headerSize") Unit[] units;
}

void testArrayLengthExpr() {
    immutable ubyte[] bytes = [3, 0, 7, 0, 8, //header
                               0, 7, 1, 2,
                               0, 6, 2, 3,
                               0, 5, 4, 5];
    auto pkt = decerealise!PacketWithArrayLengthExpr(bytes);

    pkt.ub.shouldEqual(3);
    pkt.us.shouldEqual(7);
    pkt.units.length.shouldEqual(3);

    pkt.units[2].us.shouldEqual(5);
    pkt.units[2].ub1.shouldEqual(4);
    pkt.units[2].ub2.shouldEqual(5);

    auto enc = Cerealiser();
    enc ~= pkt;
    enc.bytes.shouldEqual(bytes);
}


struct NegativeStruct {
    enum len = -1;
    ushort us;
    @ArrayLength("len") Unit[] units;
}

void testNegativeLength() {
    immutable ubyte[] bytes = [1, 2, 3, 4, 5];
    decerealise!NegativeStruct(bytes).shouldThrow!CerealException;
}


void testNotEnoughBytes() {
    immutable ubyte[] bytes = [3, 0, 7, 0, 8, //header
                               0, 7]; //truncated
    decerealise!PacketWithArrayLengthExpr(bytes).shouldThrow!CerealException;
}


struct PacketWithLengthInBytes {
    static struct Header {
        ubyte ub;
        ushort lengthNoHeader;
    }

    enum headerSize = unalignedSizeof!Header;
    alias header this;

    Header header;
    @LengthInBytes("lengthNoHeader - headerSize") Unit[] units;
}

void testLengthInBytes() {
    immutable ubyte[] bytes = [ 7, 0, 11, //header (11 bytes = hdr + 2 units of 4 bytes each)
                                0, 3, 1, 2,
                                0, 9, 3, 4,
        ];
    auto pkt = decerealise!PacketWithLengthInBytes(bytes);

    pkt.ub.shouldEqual(7);
    pkt.lengthNoHeader.shouldEqual(11);
    pkt.units.length.shouldEqual(2);

    pkt.units[0].us.shouldEqual(3);
    pkt.units[0].ub1.shouldEqual(1);
    pkt.units[0].ub2.shouldEqual(2);

    pkt.units[1].us.shouldEqual(9);
    pkt.units[1].ub1.shouldEqual(3);
    pkt.units[1].ub2.shouldEqual(4);

    auto enc = Cerealiser();
    enc ~= pkt;
    enc.bytes.shouldEqual(bytes);
}


struct BigUnit {
    int i1;
    int i2;
}

struct BigUnitPacket {
    enum headerSize = totalLength.sizeof;
    ushort totalLength;
    @LengthInBytes("totalLength - headerSize") BigUnit[] units;
}

void testLengthInBytesOneUnit() {
    immutable ubyte[] bytes = [ 0, 10, //totalLength = 1 unit of size 8 + header size of 1
                                0, 0, 0, 1, 0, 0, 0, 2
        ];
    auto pkt = decerealise!BigUnitPacket(bytes);

    pkt.totalLength.shouldEqual(bytes.length);
    pkt.units.length.shouldEqual(1);
    pkt.units[0].i1.shouldEqual(1);
    pkt.units[0].i2.shouldEqual(2);

    auto enc = Cerealiser();
    enc ~= pkt;
    enc.bytes.shouldEqual(bytes);
}


@("RestOfPacket with LengthInBytes")
unittest {
    struct Small {
        ushort v;
    }
    struct Unit {
        ushort length;
        @LengthInBytes("length - 2") Small[] smalls;
    }
    struct Struct {
        @RestOfPacket Unit[] units;
    }
    immutable ubyte[] bytes =
        [
            0, 6, //length
            0, 1, 0, 2, // smalls
            0, 4, //length
            0, 3, //smalls
        ];

    auto dec = Decerealiser(bytes);
    auto pkt = dec.value!Struct;

    pkt.shouldEqual(
        Struct([Unit(6,
                     [
                         Small(1),
                         Small(2),
                     ]
                       ),
                Unit(4,
                    [
                        Small(3),
                    ]
                    )]));
}
