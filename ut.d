import unit_threaded.runner;
import std.stdio;

int main(string[] args) {
    writeln("\nAutomatically generated file ut.d");
    writeln(`Running unit tests from dirs ["tests"]
`);
    return runTests!("tests.reset", "tests.enums", "tests.decode", "tests.api", "tests.encode", "tests.encode_decode", "tests.bugs", "tests.structs", "tests.classes")(args);
}
