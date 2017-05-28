module cerealed.cerealiser;


import cerealed.cereal: grain;
import cerealed.range: DynamicArrayRange, ScopeBufferRange, isCerealiserRange;
import cerealed.traits: isCereal, isCerealiser;
import concepts: models;
import std.array: Appender;


alias AppenderCerealiser = CerealiserImpl!(Appender!(ubyte[]));
alias DynamicArrayCerealiser = CerealiserImpl!DynamicArrayRange;
alias ScopeBufferCerealiser = CerealiserImpl!ScopeBufferRange;

alias Cerealiser = AppenderCerealiser; //the default, easy option

/**
 * Uses a ScopeBufferCerealiaser to write the bytes. The reason
 * it takes a function as a template parameter is to be able
 * to do something with the bytes. The bytes shouldn't be used
 * directly because once the function exits that is no longer
 * valid memory (it's been popped off the stack or freed).
 */
auto cerealise(alias F, ushort N = 32, T)(auto ref T val) @system  {
    static assert(N % 2 == 0, "cerealise must be passed an even number of bytes");
    ubyte[N] buf = void;
    auto sbufRange = ScopeBufferRange(buf);
    auto enc = ScopeBufferCerealiser(sbufRange);
    enc ~= val;
    static if(is(ReturnType!F == void)) {
         F(enc.bytes);
    } else {
         return F(enc.bytes);
    }
}

/**
 * Slower version of $(D cerealise) that returns a ubyte slice.
 * It's preferable to use the version with the lambda template alias
 */
ubyte[] cerealise(T)(auto ref T val) {
    auto enc = Cerealiser();
    enc ~= val;
    return enc.bytes.dup;
}

alias cerealize = cerealise;

@models!(Cerealiser, isCereal)
@models!(Cerealiser, isCerealiser)
struct CerealiserImpl(R) if(isCerealiserRange!R) {

    import cerealed.cereal: CerealType;
    import std.traits: isArray, isAssociativeArray, isDynamicArray, isAggregateType, Unqual;

    //interface
    enum type = CerealType.WriteBytes;

    void grainUByte(ref ubyte val) @trusted {
        _output.put(val);
    }

    void grainBits(ref uint value, int bits) @safe {
        writeBits(value, bits);
    }

    void grainClass(T)(T val) @trusted if(is(T == class)) {
        import cerealed.cereal: grainClassImpl;

        if(val.classinfo.name in _childCerealisers) {
            _childCerealisers[val.classinfo.name](this, val);
        } else {
            grainClassImpl(this, val);
        }
    }

    void grainRaw(ubyte[] val) @trusted {
        _output.put(val);
    }

    //specific:
    this(R r) {
        _output = r;
    }

    const(ubyte[]) bytes() const nothrow @property @safe {
        return _output.data;
    }

    ref CerealiserImpl opOpAssign(string op : "~", T)(T val) @safe {
        write(val);
        return this;
    }

    void write(T)(T val) @safe if(!isArray!T && !isAssociativeArray!T) {
        Unqual!T lval = val;
        grain(this, lval);
    }

    void write(T)(const ref T val) @safe if(!isDynamicArray!T &&
                                            !isAssociativeArray!T &&
                                            !isAggregateType!T) {
        T lval = val;
        grain(this, lval);
    }

    void write(T)(const(T)[] val) @trusted {
        auto lval = cast(T[])val.dup;
        grain(this, lval);
    }

    void write(K, V)(const(V[K]) val) @trusted {
        auto lval = cast(V[K])val.dup;
        grain(this, lval);
    }

    void writeBits(in int value, in int bits) @safe {
        import std.conv: text;
        import std.exception: enforce;

        enforce(value < (1 << bits), text("value ", value, " too big for ", bits, " bits"));
        enum bitsInByte = 8;
        if(_bitIndex + bits >= bitsInByte) { //carries over to next byte
            const remainingBits = _bitIndex + bits - bitsInByte;
            const thisByteValue = (value >> remainingBits);
            _currentByte |= thisByteValue;
            grainUByte(_currentByte);
            _currentByte = 0;
            _bitIndex = 0;
            if(remainingBits > 0) {
                ubyte remainingValue = value & (0xff >> (bitsInByte - remainingBits));
                writeBits(remainingValue, remainingBits);
            }
            return;
        }
        _currentByte |= (value << (bitsInByte - bits - _bitIndex));
        _bitIndex += bits;
    }

    void reset() @safe {
        _output.clear();
    }

    static void registerChildClass(T)() @safe {
        import cerealed.cereal: grainClassImpl;
        _childCerealisers[T.classinfo.name] = (ref Cerealiser cereal, Object val) {
            T child = cast(T)val;
            cereal.grainClassImpl(child);
        };
    }

private:

    R _output;
    ubyte _currentByte;
    int _bitIndex;
    alias ChildCerealiser = void function(ref CerealiserImpl cereal, Object val);
    static ChildCerealiser[string] _childCerealisers;

    // static assert(isCereal!CerealiserImpl);
    // static assert(isCerealiser!CerealiserImpl);
}
