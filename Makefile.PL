use ExtUtils::MakeMaker;

use YAML::Any qw(LoadFile);
my $file = "plugins/LexBlogSkin/config.yaml";
my $version = LoadFile($file)->{version} ||
    die "No version found in $file";

WriteMakefile(
    NAME            => 'LexBlog Skin',
    VERSION         => $version,
    DISTNAME        => 'LexBlogSkin',
);
