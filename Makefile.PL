use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'url',
    AUTHOR              => q{YOUR NAME <youremail@example.com>},
    VERSION_FROM        => 'lib/url.pm',
    ABSTRACT            => 'YOUR APPLICATION ABSTRACT',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer'     => 1.3012,
        'Dancer::Plugin::Redis' => 0,
        'Template' => 0,
        'Moose'      => 0,
        'Data::Rand' => 0,
        'File::Spec' => 0,
        'Digest::SHA1' => 0,
        'Carp' => 0,
        'File::Basename' => 0,
        'File::Path' => 0,
        'File::Spec' => 0,
        'DateTime' => 0,
        'URI::Escape' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'url-*' },
);

