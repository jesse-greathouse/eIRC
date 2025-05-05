#!/usr/bin/perl

package eIRC::Install::Ubuntu;
use strict;
use Cwd qw(getcwd abs_path);
use File::Basename;
use lib dirname(abs_path(__FILE__)) . "/modules";
use eIRC::Utility qw(command_result);
use eIRC::System qw(how_many_threads_should_i_use);
use Exporter 'import';

our @EXPORT_OK = qw(install_system_dependencies install_php install_bazelisk);

my @systemDependencies = qw(
    supervisor authbind expect openssl build-essential intltool autoconf
    automake gcc-13 g++-13 libstdc++-13-dev curl pkg-config cpanminus 
    libncurses-dev libpcre3-dev libcurl4 libcurl4-openssl-dev libmagickwand-dev 
    libssl-dev libxslt1-dev libmysqlclient-dev libxml2 libxml2-dev libicu-dev
    libmagick++-dev libzip-dev libonig-dev libsodium-dev libglib2.0-dev
    libwebp-dev mysql-client imagemagick golang-go
);

# ====================================
# Subroutines
# ====================================

# Installs OS-level system dependencies.
sub install_system_dependencies {
    my $username = getpwuid($<);
    print "Sudo is required for updating and installing system dependencies.\n";
    print "Please enter sudoers password for: $username elevated privileges.\n";

    # Add the PPA toolchain for C++
    add_toolchain_ppa();

    # Check if the golang PPA is already present
    my $ppa_check_cmd = q{
        grep -rq 'longsleep/golang-backports' /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null
    };
    my $ppa_exists = system('bash', '-c', $ppa_check_cmd);

    if ($ppa_exists != 0) {
        my @addPpaCmd = ('sudo', 'add-apt-repository', '-y', 'ppa:longsleep/golang-backports');
        system(@addPpaCmd);
        command_result($?, $!, "Added Golang Repository...", \@addPpaCmd);
    } else {
        print "✓ Golang PPA already exists, skipping.\n";
    }

    # Update apt cache
    my @updateCmd = ('sudo', 'apt-get', 'update');
    system(@updateCmd);
    command_result($?, $!, "Updated package index...", \@updateCmd);

    # Filter system dependencies: only keep those that aren't already installed
    my @to_install;
    foreach my $pkg (@systemDependencies) {
        my $check = system("dpkg -s $pkg > /dev/null 2>&1");
        if ($check != 0) {
            push @to_install, $pkg;
        } else {
            print "✓ $pkg already installed, skipping.\n";
        }
    }

    # Install only what’s missing
    if (@to_install) {
        my @installCmd = ('sudo', 'apt-get', 'install', '-y', @to_install);
        system(@installCmd);
        command_result($?, $!, "Installed missing dependencies...", \@installCmd);
    } else {
        print "All system dependencies already installed.\n";
    }

    # Set GCC 13 and G++ 13 as default compilers if installed
    my $gcc13 = system("which gcc-13 > /dev/null 2>&1");
    my $gpp13 = system("which g++-13 > /dev/null 2>&1");

    if ($gcc13 == 0 && $gpp13 == 0) {
        system('sudo', 'update-alternatives', '--install', '/usr/bin/gcc', 'gcc', '/usr/bin/gcc-13', '100');
        system('sudo', 'update-alternatives', '--install', '/usr/bin/g++', 'g++', '/usr/bin/g++-13', '100');
        print "✓ GCC and G++ have been set to version 13.\n";
    } else {
        print "⚠ GCC 13 or G++ 13 not found after installation.\n";
    }
}

# Installs PHP.
sub install_php {
    my ($dir) = @_;
    my $threads = how_many_threads_should_i_use();

    my @configurePhp = (
        './configure',
        '--prefix=' . $dir . '/opt/php',
        '--sysconfdir=' . $dir . '/etc',
        '--with-config-file-path=' . $dir . '/etc/php',
        '--with-config-file-scan-dir=' . $dir . '/etc/php/conf.d',
        '--enable-opcache', '--enable-fpm', '--enable-dom', '--enable-exif',
        '--enable-fileinfo', '--enable-mbstring', '--enable-bcmath',
        '--enable-intl', '--enable-ftp', '--enable-pcntl', '--enable-gd',
        '--enable-soap', '--enable-sockets', '--without-sqlite3',
        '--without-pdo-sqlite', '--with-libxml', '--with-xsl', '--with-zlib',
        '--with-curl', '--with-webp', '--with-openssl', '--with-zip', '--with-bz2',
        '--with-sodium', '--with-mysqli', '--with-pdo-mysql', '--with-mysql-sock',
        '--with-iconv'
    );

    my $originalDir = getcwd();

    # Unpack PHP Archive
    my ($archive) = glob("$dir/opt/php-*.tar.gz");

    unless ($archive && -e $archive) {
        die "PHP archive not found: $dir/opt/php-*.tar.gz\n";
    }

    system('tar', '-xzf', $archive, '-C', "$dir/opt/");
    command_result($?, $!, 'Unpacked PHP Archive...', ['tar', '-xzf', $archive, '-C', "$dir/opt/"]);

    chdir glob("$dir/opt/php-*/");

    # Configure PHP
    system(@configurePhp);
    command_result($?, $!, 'Configured PHP...', \@configurePhp);

    # Make and Install PHP
    print "\n=================================================================\n";
    print " Compiling PHP...\n";
    print "=================================================================\n\n";
    print "Running make using $threads threads in concurrency.\n\n";

    system('make', "-j$threads");
    command_result($?, $!, 'Made PHP...', 'make');

    system('make install');
    command_result($?, $!, 'Installed PHP...', 'make install');

    chdir $originalDir;
}

# installs Bazelisk.
sub install_bazelisk {
    my ($dir) = @_;
    my $originalDir = getcwd();
    my $bazeliskDir = "$dir/opt/bazelisk/";

    # If elixir directory exists, delete it.
    if (-d $bazeliskDir) {
        print "Bazel dependency already exists, skipping...(`rm -rf $bazeliskDir` to rebuild)\n";
        return;
    }

    # Unpack
    system(('bash', '-c', "tar -xzf $dir/opt/bazelisk-*.tar.gz -C $dir/opt/"));
    command_result($?, $!, 'Unpack Bazelisk...', "tar -xzf $dir/opt/bazelisk-*.tar.gz -C $dir/opt/");

    # Rename
    system(('bash', '-c', "mv $dir/opt/bazelisk-*/ $bazeliskDir"));
    command_result($?, $!, 'Renaming Bazelisk Dir...', "mv -xzf $dir/opt/bazelisk-*/ $bazeliskDir");

    chdir glob($bazeliskDir);

    # Install Bazelisk
    print "\n=================================================================\n";
    print " Installing Bazelisk....\n";
    print "=================================================================\n\n";

    # Install
    system('bash', '-c', 'go install github.com/bazelbuild/bazelisk@latest');
    command_result($?, $!, 'Install Bazelisk...', 'go install github.com/bazelbuild/bazelisk@latest');

    # Binary
    system('bash', '-c', "GOOS=linux GOARCH=amd64 go build -o $dir/bin/bazel");
    command_result($?, $!, 'Build Bazelisk...', "GOOS=linux GOARCH=amd64 go build -o $dir/bin/bazel");

    system('bash', '-c', "$dir/bin/bazel version");
    command_result($?, $!, 'Run Bazelisk...', "$dir/bin/bazel version");

    chdir $originalDir;
}

sub add_toolchain_ppa {
    # Check current GCC version
    my $gcc_version_output = `gcc -dumpversion 2>/dev/null`;
    chomp $gcc_version_output;

    if ($gcc_version_output =~ /^(\d+)\./) {
        my $major_version = $1;
        if ($major_version >= 13) {
            print "✓ GCC version $gcc_version_output is sufficient (>=13), skipping toolchain PPA.\n";
            return;
        }
    }

    # Add the PPA if not already added
    my $ppa_check_cmd = q{
        grep -rq 'ubuntu-toolchain-r/test' /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null
    };
    my $ppa_exists = system('bash', '-c', $ppa_check_cmd);

    if ($ppa_exists != 0) {
        print "GCC too old ($gcc_version_output), adding toolchain PPA for newer GCC...\n";
        my @addPpaCmd = ('sudo', 'add-apt-repository', '-y', 'ppa:ubuntu-toolchain-r/test');
        system(@addPpaCmd);
        command_result($?, $!, "Added Toolchain PPA...", \@addPpaCmd);
    } else {
        print "✓ Toolchain PPA already exists, skipping.\n";
    }
}

1;
