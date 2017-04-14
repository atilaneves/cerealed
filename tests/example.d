module tests.example;

@("example")
unittest {
    import cerealed;
    assert(cerealise(5) == [0, 0, 0, 5]); // returns ubyte[]
    cerealise!(a => assert(a == [0, 0, 0, 5]))(5); // faster than using the bytes directly

    assert(decerealise!int([0, 0, 0, 5]) == 5);

    struct Foo { int i; }
    const foo = Foo(5);
    // alternate spelling
    assert(foo.cerealize.decerealize!Foo == foo);
}
