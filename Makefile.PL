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
        'Getopt::Long' => 0,
        'Pod::Usage' => 0,
        'YAML::XS' => 0,
        'Cwd' => 0,
        'Net::DBus' => 0,
        'Proc::Daemon' => 0,
        'Time::HiRes' => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Service-WorkHours-*' },
);
