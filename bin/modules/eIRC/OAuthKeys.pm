#!/usr/bin/perl

package eIRC::OAuthKeys;
use strict;
use warnings;
use Exporter 'import';
use File::Basename;
use Cwd qw(abs_path);

our @EXPORT_OK = qw(generate_oauth_keys);

# Generates a 4096-bit RSA key pair using openssl
sub generate_oauth_keys {
    my ($private_key_path, $public_key_path) = @_;

    unlink $private_key_path if -e $private_key_path;
    unlink $public_key_path if -e $public_key_path;

    system('openssl', 'genrsa', '-out', $private_key_path, '4096') == 0
        or die "Failed to generate private key: $!";

    system('openssl', 'rsa', '-in', $private_key_path, '-pubout', '-out', $public_key_path) == 0
        or die "Failed to generate public key: $!";

    # Set secure file permissions
    chmod 0600, $private_key_path or warn "Could not set permissions on $private_key_path: $!";
    chmod 0600, $public_key_path or warn "Could not set permissions on $public_key_path: $!";
}

1;
