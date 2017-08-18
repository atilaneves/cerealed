import reggae;

alias ut = dubTestTarget!(CompilerFlags("-g -debug"));
alias utl = dubConfigurationTarget!(Configuration("ut"),
                                    CompilerFlags("-g -debug -unittest -version=unitThreadedLight"));
mixin build!(ut, utl);
