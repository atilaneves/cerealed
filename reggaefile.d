import reggae;
import std.typecons;

alias ut = dubTestTarget!(CompilerFlags("-w -g -debug"),
                          LinkerFlags(),
                          Yes.allTogether);
alias utl = dubConfigurationTarget!(Configuration("ut"),
                                    CompilerFlags("-w -g -debug -unittest -version=unitThreadedLight"));
mixin build!(ut, utl);
