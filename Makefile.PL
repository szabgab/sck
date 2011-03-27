use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'url',
    AUTHOR       => q{Geistteufel <geistteufel@yahoo.fr>},
    VERSION_FROM => 'lib/Celogeek/URL.pm',
    ABSTRACT     => 'Celogeek::URL Dancer App',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'YAML'                  => 0,
        'Dancer'                => 1.3020,
        'Dancer::Plugin::Redis' => 0,
        'Template'              => 0,
        'Mouse'                 => 0,
        'Data::Rand'            => 0,
        'File::Spec'            => 0,
        'Digest::SHA1'          => 0,
        'Carp'                  => 0,
        'File::Basename'        => 0,
        'File::Path'            => 0,
        'File::Spec'            => 0,
        'DateTime'              => 0,
        'URI::Escape'           => 0,
        'WWW::GetPageTitle'     => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'url-*' },
);

