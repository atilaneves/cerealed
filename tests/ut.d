#!/usr/bin/rdmd -Itests


import unit_threaded.runner;


int main(string[] args) {
    return runTests!("encode", "decode", "encode_decode", "structs", "klasses")(args);
}
