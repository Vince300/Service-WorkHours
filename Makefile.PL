use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Service::WorkHours',
    AUTHOR           => q{Vincent Tavernier <vince.tavernier@gmail.com>},
    VERSION_FROM     => 'lib/Service/WorkHours.pm',
    ABSTRACT_FROM    => 'lib/Service/WorkHours.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.014',
    EXE_FILES => [
        'scripts/workhoursd'
    ],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Service-WorkHours-*' },
);
