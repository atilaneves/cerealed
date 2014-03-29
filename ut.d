import unit_threaded.runner;
import std.stdio;

int main(string[] args) {
    writeln("\nAutomatically generated file ut.d");
    writeln(`Running unit tests from dirs ["tests"]
`);
    return runTests!("tests.cerealiser_impl", "tests.reset", "tests.enums", "tests.decode", "tests.pointers", "tests.encode", "tests.encode_decode", "tests.bugs", "tests.structs", "tests.classes", "tests.range")(args);
}
