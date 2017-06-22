#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Service::WorkHours' ) || print "Bail out!\n";
}

diag( "Testing Service::WorkHours $Service::WorkHours::VERSION, Perl $], $^X" );
