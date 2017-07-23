package Service::WorkHours::Systemd;

use 5.014;
use strict;
use warnings;
use Carp;

use Net::DBus;

=head1 NAME

Service::WorkHours::Systemd - Wrapper for access to systemd via DBus

=head1 SYNOPSIS

This class provides a wrapper for loading unit files from systemd through DBus.

	use Service::WorkHours::Systemd;
	my $systemd = Service::WorkHours::Systemd->new;
	say $systemd->get_unit("nginx.service")->ActiveState;

=head1 METHODS

=cut

=head2 new()

Initializes a new instance of the systemd DBus wrapper class.

=cut

sub new {
	my ($class, %opts) = @_;

	my $self = {
		bus => Net::DBus->system
	};

	$self->{systemd} = $self->{bus}->get_service("org.freedesktop.systemd1");
	$self->{manager} = $self->{systemd}->get_object("/org/freedesktop/systemd1");

	bless $self, $class;
}

=head2 get_unit($name)

Tries to load and retrieve the unit object associated with C<$name>. If the unit
cannot be loaded, C<undef> is returned.

=cut

sub get_unit {
	my ($self, $unitname) = @_;

	# Ask systemd to load the unit file
	my $unit = $self->{manager}->LoadUnit($unitname);

	if ($unit) {
		# Get the actual unit object
		$unit = $self->{systemd}->get_object($unit);

		# Print notification about loading
		my $path = $unit->FragmentPath || $unit->SourcePath;
		say STDERR "Loaded $unitname from $path";

		return $unit;
	} else {
		# No unit found
		return undef;
	}
}

=head1 AUTHOR

Vincent Tavernier, C<< <vince.tavernier at gmail.com> >>

=cut

1;
