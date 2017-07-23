package Service::WorkHours::Config;

use 5.014;
use strict;
use warnings;
use Carp;

use File::Basename qw/dirname/;
use File::Glob ':bsd_glob';
use File::Spec::Functions qw/catfile file_name_is_absolute/;
use YAML;

=head1 NAME

Service::WorkHours::Config - Configuration class for workhoursd

=head1 SYNOPSIS

This class loads service specifications from a YAML formatted configuration file
and loads the corresponding units from a given systemd wrapper (see
L<Systemd::WorkHours::Systemd>).

	use Service::WorkHours::Config;
	use Service::WorkHours::Systemd;
	my $config = Service::WorkHours::Config->new(
		file => '/etc/workhoursd',
		systemd => Service::WorkHours::Systemd->new
	);
	say keys %{$config->services};


=head1 METHODS

=cut

sub _str2timeofday {
	$_[0] =~ m/^(\d{1,2}):(\d{1,2})$/;
	my $t = $1 * 3600 + $2 * 60;

	die "Invalid time $t" if ($t < 0 || $t > (24*3600));
	return $t;
}

=head2 new(file => $path, systemd => $wrapper)

Loads a new configuration from the file specified by C<$path> and loads the
units corresponding to services from the given C<$wrapper>. Returns a new
instance representing this configuration.

=cut

sub new {
	my ($class, %opts) = @_;

	croak "file must be specified"
		unless $opts{file};

	croak "no systemd wrapper provided"
		unless $opts{systemd};

	# Default to includes enabled
	$opts{includes} //= 1;

	my $self = {
		services => {}
	};

	my @files = ref $opts{file} eq 'ARRAY' ?
	 			@{$opts{file}} : ($opts{file});
	my $loaded = 0;

	while (my $configfile = shift @files) {
		# Try to load config or warn
		my $config = eval { YAML::LoadFile($configfile) // {} };
		if ($@) {
			carp "cannot load config file $configfile: $@";
			next
		};

		my $dir = dirname($configfile);

		while (my ($k, $v) = each %{$config->{services} // {}}) {
			# Try to load the unit from systemd
			my $unit = defined $self->{services}->{$k} ?
						$self->{services}->{$k}->{unit} : # overriding, reuse unit
			 			$opts{systemd}->get_unit("$k.service");

			if ($unit) {
				my $svc = {
					name => $k,
					unit => $unit,
					startat => _str2timeofday($v->{start}),
					stopat => _str2timeofday($v->{stop}),
					ignorefailed => $v->{ignorefailed} // 0
				};

				# Check start and stop date
				if ($svc->{startat} >= $svc->{stopat}) {
					carp "'$k' is set to stop before it starts, ignoring.";
					next
				}

				# Unit has been found and is valid, register service
				$self->{services}->{$k} = $svc;
			} else {
				carp "'$k' has no matching service unit, ignoring.";
			}
		}

		# Process includes, unless disabled
		if ($opts{includes}) {
			if (ref $config->{include} eq 'ARRAY') {
				for my $inc (@{$config->{include}}) {
					# Each include can be a glob, which can itself be relative
					# to the current configuration file
					$inc = catfile($dir, $inc) unless
						file_name_is_absolute($inc);

					push @files, bsd_glob($inc);
				}
			}
		}

		$loaded++;
	}

	# Fail if no files could be loaded
	croak "could not load any config files" unless $loaded;

	bless $self, $class;
}

=head2 services()

Returns the services represented by this configuration instance.

=cut

sub services {
	my ($self) = @_;
	$self->{services}
}

=head1 AUTHOR

Vincent Tavernier, C<< <vince.tavernier at gmail.com> >>

=cut

1;
