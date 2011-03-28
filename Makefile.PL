use ExtUtils::MakeMaker;

use YAML::Any qw(LoadFile);
my $file = "plugins/MelodyMaker/config.yaml";
my $version = LoadFile($file)->{version} ||
    die "No version found in $file";

WriteMakefile(
    NAME            => 'Melody Maker',
    VERSION         => $version,
    DISTNAME        => 'MelodyMaker',
);
