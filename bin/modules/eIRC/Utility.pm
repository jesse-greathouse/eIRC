#!/usr/bin/perl

package eIRC::Utility;
use strict;
use Exporter 'import';
use Errno;
use POSIX 'ceil';

our @EXPORT_OK = qw(
  command_result
  get_operating_system
  read_file
  write_file
  trim
  splash
  str_replace_in_file
  generate_rand_str
  is_pid_running
);

# ====================================
#    Subroutines below this point
# ====================================

# Trim the whitespace from a string.
sub trim {
    my $s = shift;
    $s =~ s/^\s+|\s+$//g;
    return $s;
}

# Returns string associated with operating system.
sub get_operating_system {
    my %osNames = (
        MSWin32 => 'Win32',
        NetWare => 'Win32',
        symbian => 'Win32',
        darwin  => 'MacOS'
    );

    # Check for Linux-based OS and delegate to a separate function
    if ($^O eq 'linux') {
        return get_linux_distribution();
    }

    # If $^O is not found in the hash, die with an error message
    die "Unsupported operating system: $^O\n" unless exists $osNames{$^O};

    return $osNames{$^O};
}

# Detects the Linux distribution.
sub get_linux_distribution {
    # Arrays for different types of distribution identification
    my @os_release_dists = (
        { pattern => 'centos',          name => 'CentOS' },
        { pattern => 'ubuntu',          name => 'Ubuntu' },
        { pattern => 'fedora',          name => 'Fedora' },
        { pattern => 'debian',          name => 'Debian' },
        { pattern => 'opensuse',        name => 'OpenSUSE' },
        { pattern => 'arch',            name => 'Arch' },
        { pattern => 'alpine',          name => 'Alpine' },
        { pattern => 'gentoo',          name => 'Gentoo' },
        { pattern => 'openmandriva',    name => 'OpenMandriva' },
    );

    # Check /etc/os-release first (most modern distros)
    if (open my $fh, '<', '/etc/os-release') {
        while (my $line = <$fh>) {
            foreach my $dist (@os_release_dists) {
                if ($line =~ /^ID=$dist->{pattern}/) {
                    return $dist->{name};
                }
            }
        }
    }

    # Fallback to other common files
    if (-e '/etc/lsb-release') {
        if (open my $fh, '<', '/etc/lsb-release') {
            while (my $line = <$fh>) {
                foreach my $dist (@os_release_dists) {
                    if ($line =~ /DISTRIB_ID=$dist->{name}/i) {
                        return $dist->{name};
                    }
                }
            }
        }
    }

    if (-e '/etc/redhat-release') {
        if (open my $fh, '<', '/etc/redhat-release') {
            while (my $line = <$fh>) {
                foreach my $dist (@os_release_dists) {
                    if ($line =~ /$dist->{name}/i) {
                        return $dist->{name};
                    }
                }
            }
        }
    }

    # Check /etc/debian_version for Debian-based distros
    if (-e '/etc/debian_version') {
        return 'Debian';
    }

    # Use uname as a last resort (generic fallback)
    my $uname = `uname -a`;
    foreach my $dist (@os_release_dists) {
        if ($uname =~ /$dist->{name}/i) {
            return $dist->{name};
        }
    }

    # If no distribution was found, throw an error
    die "Unable to determine Linux distribution.\n";
}

# Replaces all occurrences of a string with another string inside a file.
sub str_replace_in_file {
    my ($string, $replacement, $file) = @_;
    my $data = read_file($file);
    $data =~ s/\Q$string/$replacement/g;
    write_file($file, $data);
}

# Reads the contents of a UTF-8 encoded file and returns it as a string.
sub read_file {
    my ($filename) = @_;

    open my $in, '<:encoding(UTF-8)', $filename or die "Could not open '$filename' for reading $!";
    local $/ = undef;
    my $all = <$in>;
    close $in;

    return $all;
}

# Writes a string to a UTF-8 encoded file.
sub write_file {
    my ($filename, $content) = @_;

    open my $out, '>:encoding(UTF-8)', $filename or die "Could not open '$filename' for writing $!";
    print $out $content;
    close $out;

    return;
}

# Handles system command exit status and prints a result message.
sub command_result {
    my ($exit, $err, $operation_str, @cmd) = @_;

    if ($exit == -1) {
        print "Failed to execute command: $err\n";
        print "Command: @cmd\n" if @cmd;
        exit 1;
    }
    elsif ($exit & 127) {
        my $signal = $exit & 127;
        my $coredump = ($exit & 128) ? 'with' : 'without';
        print "Command died with signal $signal ($coredump coredump).\n";
        print "Command: @cmd\n" if @cmd;
        exit 1;
    }
    else {
        my $code = $exit >> 8;
        if ($code != 0) {
            print "Command exited with non-zero status $code.\n";
            print "Command: @cmd\n" if @cmd;
            exit $code;
        }
        else {
            print "$operation_str success!\n";
        }
    }
}

# Generates a random hexadecimal string of a given length (default: 64 characters).
sub generate_rand_str {
    my ($length) = @_;
    $length //= 64;

    # Each byte = 2 hex chars, so we need ceil(length / 2) bytes
    my $bytes_needed = ceil($length / 2);

    open my $urandom, '<:raw', '/dev/urandom' or die "Can't open /dev/urandom: $!";
    read($urandom, my $raw, $bytes_needed) == $bytes_needed or die "Failed to read enough bytes from /dev/urandom";
    close $urandom;

    my $hex = uc unpack('H*', $raw);   # Convert to uppercase hex
    return substr($hex, 0, $length);   # Truncate length
}

# Checks whether a PID from a file is currently running.
sub is_pid_running {
    my ($pidFile) = @_;

    open my $fh, '<', $pidFile or die "Can't open $pidFile: $!";
    my $pid = do { local $/; <$fh> };
    close $fh;

    # Strip whitespace/newlines
    $pid =~ s/^\s+|\s+$//g;

    # Validate PID is numeric
    return 0 unless defined $pid && $pid =~ /^\d+$/;

    my %dispatch = (
        success     => sub { return 1 },
        no_perm     => sub { return 1 },
        not_found   => sub { return 0 },
    );

    my $result = kill(0, $pid);

    return $dispatch{
                    $result             ? 'success' :
                    $! == Errno::EPERM  ? 'no_perm' :
                                        'not_found'
    }->();
}

# Prints a splash screen message.
sub splash {
    print (''."\n");
    print ('+--------------------------------------------------------------------------------------------------------------+'."\n");
    print ('| eIRC Software License Agreement                                                                              |'."\n");
    print ('+--------------------------------------------------------------------------------------------------------------+'."\n");
    print ('| Copyright (c) 2025 Jesse Greathouse (https://github.com/jesse-greathouse/eIRC)                               |'."\n");
    print ('+--------------------------------------------------------------------------------------------------------------+'."\n");
    print ('| This Software License Agreement ("Agreement") is a legally binding document between you ("Licensee")         |'."\n");
    print ('| and Jesse Greathouse ("Licensor") for the use of the eIRC software ("Software").                             |'."\n");
    print ('| By installing, copying, or using the Software, you agree to be bound by the terms and conditions             |'."\n");
    print ('| of this Agreement. If you do not agree to these terms, you must not install, copy, or use the                |'."\n");
    print ('| Software.                                                                                                    |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| 1. Ownership and Copyright                                                                                   |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| All rights, title, and interest in and to the Software, including but not limited to all content,            |'."\n");
    print ('| features, designs, and code, are owned exclusively by Jesse Greathouse (jesse.greathouse@greathouse.com)     |'."\n");
    print ('| and are protected by copyright laws and international treaties. Unauthorized use, reproduction, or           |'."\n");
    print ('| distribution of the Software or any of its content is strictly prohibited and constitutes a violation        |'."\n");
    print ('| of copyright laws. The only valid proof of authorization is a written document or email from the             |'."\n");
    print ('| Licensor that provides a Statement of Granted Authorization ("Grant of Authorization") to the Licensee,      |'."\n");
    print ('| and any additional restrictions therin. Terms of authorization should be provided in the statement of        |'."\n");
    print ('| Grant of Authorization.                                                                                      |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| 2. Grant of Authorization                                                                                    |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| Licensor grants Licensee a limited, non-exclusive, non-transferable, and revocable license to use the        |'."\n");
    print ('| Software solely for personal or internal business purposes in accordance with this agreement and the terms   |'."\n");
    print ('| of authorization provided in the Grant of Authorization. This license does not transfer ownership of the     |'."\n");
    print ('| Software or any intellectual property rights to the Licensee.                                                |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| 3. Restrictions                                                                                              |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| Licensee agrees to the following restrictions:                                                               |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| No Unauthorized Use: The Software may not be used for any purpose not expressly authorized by this           |'."\n");
    print ('| Agreement.                                                                                                   |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| No Copying: Copying, reproducing, or distributing the Software, in whole or in part, is strictly prohibited. |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| No Reverse Engineering: Licensee may not modify, decompile, disassemble, or reverse engineer the Software.   |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| No Derivative Works: Licensee may not create derivative works based on the Software or its content.          |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| No Transfer: Licensee may not sublicense, rent, lease, or transfer the Software to any third party.          |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| 4. Disclaimer of Warranty                                                                                    |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| THE SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED |'."\n");
    print ('| TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. LICENSOR MAKES |'."\n");
    print ('| NO WARRANTY THAT THE SOFTWARE WILL BE ERROR-FREE, SECURE, OR OPERATE WITHOUT INTERRUPTION.                   |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| 5. Limitation of Liability                                                                                   |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| In no event shall Licensor be liable for any damages (including, without limitation, lost profits, business  |'."\n");
    print ('| interruption, or loss of information) arising out of the use or inability to use the Software, even if       |'."\n");
    print ('| Licensor has been advised of the possibility of such damages.                                                |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| 6. Termination                                                                                               |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| This Agreement is effective until terminated. Licensor may terminate this Agreement at any time. Upon        |'."\n");
    print ('| termination, Licensee must immediately cease using the Software and destroy all copies of the Software in    |'."\n");
    print ('| their possession.                                                                                            |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| 7. Governing Law                                                                                             |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| This Agreement shall be governed by and construed in accordance with the laws of the jurisdiction in which   |'."\n");
    print ('| Licensor resides, without regard to its conflict of law provisions.                                          |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| 8. Entire Agreement                                                                                          |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('| This Agreement constitutes the entire agreement between the parties concerning the subject matter hereof and |'."\n");
    print ('| supersedes all prior agreements or understandings, whether written or oral.                                  |'."\n");
    print ('|                                                                                                              |'."\n");
    print ('+--------------------------------------------------------------------------------------------------------------+'."\n");
    print ('| For any questions or concerns regarding this Agreement, please contact:                                      |'."\n");
    print ('|       Jesse Greathouse <jesse.greathouse@gmail.com>                                                          |'."\n");
    print ('+--------------------------------------------------------------------------------------------------------------+'."\n");
    print ('| By using the eIRC software, you acknowledge that you have read, understood, and agree to be bound by the     |'."\n");
    print ('| the terms of this Agreement.                                                                                 |'."\n");
    print ('+--------------------------------------------------------------------------------------------------------------+'."\n");
    print (''."\n");
}

1;
