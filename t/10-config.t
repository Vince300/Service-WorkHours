#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Service::WorkHours::Config;
use FindBin qw/$Bin/;
use File::Spec::Functions qw/catfile/;
use Test::Deep;

# A dummy systemd wrapper
package Systemd::Dummy {
sub new {
	my $class = shift;
	bless {}, $class;
}

sub get_unit {
	my ($self, $unit) = @_;
	Test::More::diag "loaded $unit";
	1; # something truthy is ok
}
}

my $systemd = Systemd::Dummy->new;
my @testfiles = glob(catfile($Bin, '10-*.src.yml'));

plan tests => scalar @testfiles;

for my $testfile (@testfiles) {
	# Load expected services hash
	my $exp = $testfile;
	$exp =~ s{\.src\.}{.exp.};

	if (-f $exp) {
		$exp = YAML::LoadFile($exp);

		# Load config
		my $conf = Service::WorkHours::Config->new(file => $testfile,
												   systemd => $systemd);

		# Check results
		cmp_deeply($conf->services, $exp, $testfile);
	} else {
		# Test expected to fail
		throws_ok { Service::WorkHours::Config->new(file => $testfile,
												    systemd => $systemd) }
			qr/could not load any/,
			$testfile;
	}
}
