module tests.structs;

import unit_threaded;
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

private struct StructWithNoCereal {
    @Bits!4 ubyte nibble1;
    @Bits!4 ubyte nibble2;
    @NoCereal ushort nocereal1;
    ushort value;
    @NoCereal ushort nocereal2;
}

void testNoCereal() {
    auto cerealizer = new Cerealizer();
    cerealizer ~= StructWithNoCereal(3, 14, 42, 5, 12);
    //only nibble1, nibble2 and value should show up in bytes
    immutable bytes = [0x3e, 0x00, 0x05];
    checkEqual(cerealizer.bytes, bytes);

    auto decerealizer = new Decerealizer(bytes);
    //won't be the same as the serialised struct, since the members
    //marked with NoCereal will be set to T.init
    checkEqual(decerealizer.value!StructWithNoCereal, StructWithNoCereal(3, 14, 0, 5, 0));
}

private struct CustomStruct {
    ubyte mybyte;
    ushort myshort;
    void accept(Cereal)(ref Cereal cereal) {
        //can't call grain(this), that would cause an infinite loop
        cereal.grainAllMembers(this);
        ubyte otherbyte = 4;
        cereal.grain(otherbyte);
    }
}

void testCustomCereal() {
    auto cerealiser = new Cerealiser();
    import std.stdio;
    writeln("Serialising custom struct ");
    cerealiser ~= CustomStruct(1, 2);
    checkEqual(cerealiser.bytes, [ 1, 0, 2, 4]);

    //because of the custom serialisation, passing in just [1, 0, 2] would throw
    auto decerealiser = new Decerealiser([1, 0, 2, 4]);
    checkEqual(decerealiser.value!CustomStruct, CustomStruct(1, 2));
}


void testAttrMember() {
    //test that attributes work when calling grain member by member
    auto cereal = new Cerealizer();
    auto str = StructWithNoCereal(3, 14, 42, 5, 12);
    cereal.grainMemberWithAttr!"nibble1"(str);
    cereal.grainMemberWithAttr!"nibble2"(str);
    cereal.grainMemberWithAttr!"nocereal1"(str);
    cereal.grainMemberWithAttr!"value"(str);
    cereal.grainMemberWithAttr!"nocereal2"(str);

    //only nibble1, nibble2 and value should show up in bytes
    checkEqual(cereal.bytes, [0x3e, 0x00, 0x05]);
}

struct EnumStruct {
    enum Enum:byte {
        Foo,
        Bar,
        Baz
    }

    ubyte foo;
    Enum bar;
}

void testEnum() {
    auto cerealiser = new Cerealiser();
    const e = EnumStruct(1, EnumStruct.Enum.Baz);
    cerealiser ~= e;
    const bytes = [1, 2];
    checkEqual(cerealiser.bytes, bytes);

    auto decerealiser = new Decerealiser(bytes);
    checkEqual(decerealiser.value!EnumStruct, e);
}

struct PostBlitStruct {
    ubyte foo;
    @NoCereal ubyte bar;
    ubyte baz;
    void postBlit(Cereal)(ref Cereal cereal) {
        ushort foo = 4;
        cereal.grain(foo);
    }
}

void testPostBlit() {
    auto enc = new Cerealiser();
    enc ~= PostBlitStruct(3, 5, 8);
    const bytes = [ 3, 8, 0, 4];
    checkEqual(enc.bytes, bytes);

    auto dec = new Decerealiser(bytes);
    checkEqual(dec.value!PostBlitStruct, PostBlitStruct(3, 0, 8));
}

private struct StringsStruct {
    ubyte mybyte;
    @RawArray string[] strings;
}

void testRawArray() {
    auto enc = new Cerealiser();
    auto strs = StringsStruct(5, ["foo", "foobar", "ohwell"]);
    enc ~= strs;
    //no length encoding for the array, but strings still get a length each
    const bytes = [ 5, 0, 3, 'f', 'o', 'o', 0, 6, 'f', 'o', 'o', 'b', 'a', 'r',
                    0, 6, 'o', 'h', 'w', 'e', 'l', 'l'];
    checkEqual(enc.bytes, bytes);

    auto dec = new Decerealiser(bytes);
    checkEqual(dec.value!StringsStruct, strs);
}

void testReadmeCode() {
    struct MyStruct {
        ubyte mybyte1;
        @NoCereal uint nocereal1; //won't be serialised
        //the next 3 members will all take up one byte
        @Bits!4 ubyte nibble; //gets packed into 4 bits
        @Bits!1 ubyte bit; //gets packed into 1 bit
        @Bits!3 ubyte bits3; //gets packed into 3 bits
        ubyte mybyte2;
    }

    auto enc = new Cerealiser();
    enc ~= MyStruct(3, 123, 14, 1, 2, 42);
    import std.conv;
    assert(enc.bytes == [ 3, 0xea /*1110 1 010*/, 42], text("bytes were ", enc.bytes));

    auto dec = new Decerealizer([ 3, 0xea, 42]); //US spelling works too
    //the 2nd value is 0 and not 123 since that value
    //doesn't get serialised/deserialised
    auto val = dec.value!MyStruct;
    assert(val == MyStruct(3, 0, 14, 1, 2, 42), text("struct was ", val));
}
