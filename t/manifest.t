#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;

use Test::CheckManifest 0.9;
use Cwd qw/getcwd/;
use File::Spec::Functions qw/catfile/;
use IO::All;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my @excludes = map { chomp $_;
                     $_ = catfile(getcwd(), $_);
                     my $d = -d $_;
                     $_ =~ s{\.}{\\.}g;
                     $_ =~ s{\*}{.*}g;
                     $_ = "$_/.*" if $d;
                     qr{$_} } io('ignore.txt')->slurp;

ok_manifest({filter => \@excludes});
