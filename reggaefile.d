import reggae;

alias ut = dubConfigurationTarget!(ExeName("ut"),
                                   Configuration("unittest"),
                                   Flags("-g -debug -cov"));
mixin build!ut;
