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
		'Test::CheckManifest' => '0.9',
		'Test::Exception' => '0',
		'IO::All' => '0',
		'Test::Deep' => '0'
	},
	PREREQ_PM => {
		'Cwd' => 0,
		'File::Basename' => 0,
		'File::Glob' => 0,
		'File::Spec' => 0,
		'Getopt::Long' => 0,
		'List::Util' => 0,
		'Net::DBus' => 0,
		'Pod::Usage' => 0,
		'Proc::Daemon' => 0,
		'YAML' => 0
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Service-WorkHours-*' },
);
