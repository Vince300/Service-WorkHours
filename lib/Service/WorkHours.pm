package Service::WorkHours;

use 5.014;
use strict;
use warnings;

use Proc::Daemon;
use Net::DBus;
use Cwd qw/abs_path/;
use YAML::XS qw/LoadFile Dump/;
use Getopt::Long qw/GetOptionsFromArray/;
use List::Util qw/min/;

=head1 NAME

Service::WorkHours - Service for managing systemd services working hours

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Implementation of the Service::WorkHours daemon.

    workhoursd -d --config /etc/workhoursd

=head1 OPTIONS

=over 8

=item B<--daemon>

Enable daemon mode. Use this when you want to manually start this as a daemon,
but don't use this option if you use systemd to start workhoursd as a service.

=item B<--config>

Path to the config file for service work hours specification.

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=cut

sub _usage {
	pod2usage(@_, -input => abs_path(__FILE__));
}

sub _str2timeofday {
	$_[0] =~ m/^(\d{1,2}):(\d{1,2})$/;
	my $t = $1 * 3600 + $2 * 60;

	die "Invalid time $t" if ($t < 0 || $t > (24*3600));
	return $t;
}

=head1 SUBROUTINES

=head2 run(@args)

Implements the B<workhoursd> command.

=cut

sub run {
	shift;

	# Parse options
	my ($man, $help, $daemon, $config) = (0, 0, 0, '/etc/workhoursd');
	shift; GetOptionsFromArray(\@_, 'help|?' => \$help,
									'man' => \$man,
									'daemon' => \$daemon,
									'config=s' => \$config);

	# Print help
	_usage(-exitval => 1) if $help;
	_usage(-exitval => 0, -verbose => 2) if $man;

	# Switch to daemon mode if necessary
	Proc::Daemon::Init if $daemon;

	# State variables
	my ($continue, $reload) = (1, 0);

	# Setup signal handlers
	$SIG{TERM} = sub { $continue = 0 };
	$SIG{HUP} = sub { $reload = 1 };
	$SIG{INT} = sub { $continue = 0 };

	CONFIGLOOP:
	while ($continue) {
		# Load config
		my $config = LoadFile($config)
			or die "Could not load config file $config: $!";

		# Config reloaded
		$reload = 0;

		# Access systemd
		my $bus = Net::DBus->system;
		my $systemd = $bus->get_service("org.freedesktop.systemd1");
		my $manager = $systemd->get_object("/org/freedesktop/systemd1");

		# Build hash of systemd services
		my %services = ();

		while (my ($k, $v) = each %{$config->{services}}) {
			my $unit = $manager->LoadUnit("$k.service");

			if ($unit) {
				# Get systemd unit object
				$unit = $systemd->get_object($unit);
				
				my $p = $unit->FragmentPath || $unit->SourcePath;
				say STDERR "Loaded '$k' from '$p'";

				my $ignorefailed = $v->{ignorefailed} // 0;

				$services{$k} = { unit => $unit,
								  startat => _str2timeofday($v->{start}),
								  stopat => _str2timeofday($v->{stop}),
								  ignorefailed => $ignorefailed };
			} else {
				say STDERR "Warning: Ignoring '$k' because no matching service has been found";
			}
		}

		RUNLOOP:
		while ($continue && !$reload) {
			my $nextevent = 24*3600 + 1;

			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
				localtime(time);
			my $t = $sec + $min * 60 + $hour * 3600;

			while (my ($k, $svc) = each %services) {
				my $unit = $svc->{unit};

				# Is the unit active?
				my $active = ($unit->ActiveState =~ m/^active|reloading|activating$/);

				# Should the unit be active?
				my $should = $t >= $svc->{startat} && $t < $svc->{stopat};

				if ($active && !$should) {
					say STDERR "$k: stopping service";
					$unit->Stop("fail")
				} elsif (!$active && $should) {
					if ($unit->ActiveState eq 'failed' && !$svc->{ignorefailed}) {
						say STDERR "$k: not starting service in failed mode";
					} else {
						say STDERR "$k: starting service";
						$unit->Start("fail");
					}
				} elsif ($active && $should) {
					say STDERR "$k: running as expected";
				} elsif (!$active && !$should) {
					my $t = $svc->{startat};
					say STDERR "$k: waiting for $t";
				}

				my ($timetostart, $timetoend) = map { my $a = $svc->{$_} - $t;
													  $a <= 0 ? 24*3600+$a : $a } qw/startat stopat/;
				$nextevent = min($nextevent, $timetostart, $timetoend);
			}

			if ($nextevent == 24*3600+1) {
				sleep;
			} else {
				sleep $nextevent;
			}
		}
	}
}

=head1 AUTHOR

Vincent Tavernier, C<< <vince.tavernier at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Vincent Tavernier.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Service::WorkHours
