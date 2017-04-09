module cerealed.range;

import std.range;

template isCerealiserRange(R) {
    enum isCerealiserRange = isOutputRange!(R, ubyte) &&
        is(typeof(() { auto r = R(); r.clear(); const(ubyte)[] d = r.data; }));
}


struct DynamicArrayRange {
    void put(in ubyte val) nothrow @safe {
        _bytes ~= val;
    }

    void put(in ubyte[] val) nothrow @safe {
        _bytes ~= val;
    }

    const(ubyte)[] data() pure const nothrow @property @safe {
        return _bytes;
    }

    void clear() @trusted {
        if(_bytes !is null) {
            _bytes = _bytes[0..0];
            _bytes.assumeSafeAppend();
        }
    }

private:
    ubyte[] _bytes;
    static assert(isCerealiserRange!DynamicArrayRange);
}

struct ScopeBufferRange {
    import cerealed.scopebuffer; //change to std.internal scopebuffer in the future
    ScopeBuffer!ubyte sbuf;

    alias sbuf this;

    this(ubyte[] buf) @trusted {
        sbuf = ScopeBuffer!ubyte(buf);
    }

    ~this() {
        free;
    }

    const(ubyte)[] data() pure const nothrow @property @trusted {
        return sbuf[];
    }

    void clear() @trusted {
        sbuf.length = 0;
    }

    void free() @trusted {
        sbuf.free();
    }

    static assert(isCerealiserRange!ScopeBufferRange);
}
