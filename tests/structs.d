module tests.structs;

import unit_threaded.check;
import cerealed;
import core.exception;


private struct DummyStruct {
    int i;
    double d;
    int[] a;
    bool b;
    double[int] aa;
    string s;

    void foo() {}
}


void testDummyStruct() {
    auto enc = new Cerealiser();
    auto dummy = DummyStruct(5, 6.0, [2, 3], true, [2: 4.0], "dummy!");
    enc ~= dummy;

    auto dec = new Decerealiser(enc.bytes);
    checkEqual(dec.value!DummyStruct, dummy);

    checkThrown!RangeError(dec.value!ubyte);
}

private struct StringStruct {
    string s;
}

void testDecodeStringStruct() {
    auto dec = new Decerealiser([0, 3, 'f', 'o', 'o']);
    auto str = StringStruct();
    dec.grain(str);
    checkEqual(str.s, "foo");
    checkThrown!RangeError(dec.value!ubyte);
}

void testEncodeStringStruct() {
    auto enc = new Cerealiser();
    const str = StringStruct("foo");
    enc ~= str;
    checkEqual(enc.bytes, [ 0, 3, 'f', 'o', 'o']);
}


private struct ProtoHeaderStruct {
    @Bits!3 ubyte bits3;
    @Bits!1 ubyte bits1;
    @Bits!4 uint bits4;
    ubyte bits8; //no UDA necessary
}


void testEncDecProtoHeaderStruct() {
    const hdr = ProtoHeaderStruct(6, 1, 3, 254);
    auto enc = new Cerealiser();
    enc ~= hdr; //1101 0011, 254
    checkEqual(enc.bytes, [0xd3, 254]);

    auto dec = new Decerealiser(enc.bytes);
    checkEqual(dec.value!ProtoHeaderStruct, hdr);
}

private enum MqttType {
    RESERVED1 = 0, CONNECT = 1, CONNACK = 2, PUBLISH = 3,
    PUBACK = 4, PUBREC = 5, PUBREL = 6, PUBCOMP = 7,
    SUBSCRIBE = 8, SUBACK = 9, UNSUBSCRIBE = 10, UNSUBACK = 11,
    PINGREQ = 12, PINGRESP = 13, DISCONNECT = 14, RESERVED2 = 15
}

private struct MqttFixedHeader {
    @Bits!4 MqttType type;
    @Bits!1 bool dup;
    @Bits!2 ubyte qos;
    @Bits!1 bool retain;
    @Bits!8 uint remaining;

    this(MqttType type, bool dup, ubyte qos, bool retain, uint remaining = 0) {
        this.type = type;
        this.dup = dup;
        this.qos = qos;
        this.retain = retain;
        this.remaining = remaining;
    }
}

void testCerealiseMqttHeader() {
    auto cereal = new Cerealiser();
    cereal ~= MqttFixedHeader(MqttType.PUBLISH, true, 2, false, 5);
    checkEqual(cereal.bytes, [0x3c, 0x5]);
}

void testDecerealiseMqttHeader() {
    auto cereal = new Decerealiser([0x3c, 0x5]);
    checkEqual(cereal.value!MqttFixedHeader,
               MqttFixedHeader(MqttType.PUBLISH, true, 2, false, 5));
}

struct StructWithNoCereal {
    @Bits!4 ubyte nibble1;
    @Bits!4 ubyte nibble2;
    @NoCereal ushort nocereal1;
    ushort value;
    @NoCereal ushort nocereal2;
}

void testNoCereal() {
    auto cerealiser = new Cerealiser();
    cerealiser ~= StructWithNoCereal(3, 14, 42, 5, 12);
    //only nibble1, nibble2 and value should show up in bytes
    immutable bytes = [0x3e, 0x00, 0x05];
    checkEqual(cerealiser.bytes, bytes);

    auto decerealiser = new Decerealiser(bytes);
    //won't be the same as the serialised struct, since the members
    //marked with NoCereal will be set to T.init
    checkEqual(decerealiser.value!StructWithNoCereal, StructWithNoCereal(3, 14, 0, 5, 0));
}
