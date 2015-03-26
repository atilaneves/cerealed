module tests.static_array;

import unit_threaded;
import cerealed;

void testStaticArray() {
    int[2] original, restored;

    original[0] = 34;
    original[1] = 45;
    auto enc = Cerealiser();
    enc ~= original;
    assert(enc.bytes == [
    // no length because it's already known
        0, 0, 0, 34,
        0, 0, 0, 45,
    ]);
    auto dec = Decerealiser(enc.bytes);
    restored = dec.value!(int[2]);

    assert(original == restored);
}


void testArrayOfArrays() {
    static struct Unit {
        ubyte thingie;
        ushort length;
        @NoCereal ubyte[] data;

        void postBlit(C)(auto ref C cereal) if(isCereal!C) {
            static if(isDecerealiser!C) {
                writelnUt("Decerealiser bytesLeft ", cereal.bytesLeft);
                writelnUt("length: ", length);
            }
            cereal.grainLengthedArray(data, length);
        }
    }

    static struct Packet {
        ubyte vrsion;
        @RawArray Unit[] units;
    }

    ubyte[] bytes = [7, //vrsion
                     1, 0, 3, 0xa, 0xb, 0xc, //1st unit
                     2, 0, 5, 1, 2, 3, 4, 5 //2nd unit
        ];

    auto dec = Decerealiser(bytes);
    auto pkt = dec.value!Packet;
    pkt.shouldEqual(Packet(7, [Unit(1, 3, [0xa, 0xb, 0xc]), Unit(2, 5, [1, 2, 3, 4, 5])]));

    auto enc = Cerealiser();
    enc ~= pkt;
    enc.bytes.shouldEqual(bytes);
}
