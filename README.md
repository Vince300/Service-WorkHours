# Service::WorkHours

Service::WorkHours is a simple service written in Perl to manage systemd
services that should run during a specific period every day.

systemd timers require creating units that start and stop the service, and in
the event the host is rebooted during the service activity period, it will not
be restarted automatically. This simple program solves this problem.

## INSTALLATION

First, build and test the distribution:

    perl Makefile.PL
    make
    make test
    make dist

Install the distribution and all its dependencies using `cpanm`:

    cpanm Service-WorkHours-0.01.tar.gz

## USAGE

This module installs a `workhoursd` program which reads its configuration from
`/etc/workhoursd`, a YAML file that specifies which services should be managed.
Other options can be viewed using `workhoursd --help`.

Here is an example of configuration:

```yaml
---
services:
    nginx:
        start: 8:00  # Start at 8AM
        stop: 16:00  # Stop at 4PM
    my-service:
        start: 11:00
        stop: 12:00
        ignorefailed: 1 # Ignore the systemd failed state of the service

```

It is recommended to run `workhoursd` as a systemd service, which is enabled to
start at boot. ***It is recommended to leave managed services disabled as this
may cause conflicts at boot time with how `workhoursd` manages services***.

Here is a suitable `workhoursd.service` to run this program
as a service:

```ini
# /etc/systemd/system/workhoursd.service
[Unit]
Description=workhoursd daemon for managing services
After=local-fs.target
Requires=local-fs.target

[Service]
# Update this if you are not doing a system-wide install using cpanm
ExecStart=/usr/local/bin/workhoursd
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
```

## LICENSE AND COPYRIGHT

Copyright (C) 2017 Vincent Tavernier

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

