#!/usr/bin/perl

package eIRC::Migrate;
use strict;
use warnings;
use File::Basename;
use Cwd qw(abs_path);
use Exporter 'import';

our @EXPORT_OK = qw(migrate);

warn $@ if $@; # handle exception

# Folder Paths
my $applicationRoot = abs_path(dirname(abs_path(__FILE__)) . '/../../../');
my $srcDir = "$applicationRoot/src";
my $optDir = "$applicationRoot/opt";

# Run's the project's migrations.
sub migrate {
    system("$optDir/php/bin/php", "$srcDir/artisan", 'migrate');
}

1;
