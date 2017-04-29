import reggae;

alias ut = dubTestTarget!();
alias utl = dubConfigurationTarget!(ExeName("utl"),
                                    Configuration("ut"),
                                    Flags("-unittest -version=unitThreadedLight"));
mixin build!(ut, utl);
