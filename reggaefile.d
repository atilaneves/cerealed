import reggae;

alias ut = dubTestTarget!(CompilerFlags("-w -g -debug"),
                          LinkerFlags());
alias utl = dubConfigurationTarget!(Configuration("ut"),
                                    CompilerFlags("-w -g -debug -unittest -version=unitThreadedLight"));
mixin build!(ut, utl);
