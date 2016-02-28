import reggae;
alias ut = dubTestTarget!(Flags("-g -debug -cov"));
mixin build!ut;
