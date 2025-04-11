#!/usr/bin/perl

package eIRC::Install::Alpine;
use strict;
use Cwd qw(getcwd abs_path);
use File::Basename;
use lib dirname(abs_path(__FILE__)) . "/modules";
use eIRC::Utility qw(command_result);
use eIRC::System qw(how_many_threads_should_i_use);
use Exporter 'import';

our @EXPORT_OK = qw(install_system_dependencies install_php install_bazelisk);

my @systemDependencies = qw(
    supervisor authbind expect openssl-dev build-base intltool autoconf
    automake gcc curl pkgconf perl-app-cpanminus ncurses-dev pcre-dev
    libcurl libcurl-dev imagemagick-dev libxslt-dev mysql-dev libxml2-dev
    icu-dev imagemagick imagemagick-c++ libzip-dev oniguruma-dev
    libsodium-dev glib-dev libwebp-dev mysql-client bash musl-dev make
    go
);

sub install_system_dependencies {
    my $username = getpwuid($<);
    print "Root privileges are required for updating and installing system dependencies.\n";

    # Update apk cache
    my @updateCmd = ('apk', 'update');
    system(@updateCmd);
    command_result($?, $!, "Updated package index...", \@updateCmd);

    # Filter system dependencies
    my @to_install;
    foreach my $pkg (@systemDependencies) {
        my $check = system("apk info -e $pkg > /dev/null 2>&1");
        if ($check != 0) {
            push @to_install, $pkg;
        } else {
            print "✓ $pkg already installed, skipping.\n";
        }
    }

    if (@to_install) {
        my @installCmd = ('apk', 'add', @to_install);
        system(@installCmd);
        command_result($?, $!, "Installed missing dependencies...", \@installCmd);
    } else {
        print "All system dependencies already installed.\n";
    }
}

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

    system('bash', '-c', "tar -xzf $dir/opt/php-*.tar.gz -C $dir/opt/");
    command_result($?, $!, 'Unpacked PHP Archive...', 'tar -xzf ' . $dir . '/opt/php-*.tar.gz -C ' . $dir . '/opt/');

    chdir glob("$dir/opt/php-*/");

    system(@configurePhp);
    command_result($?, $!, 'Configured PHP...', \@configurePhp);

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

sub install_bazelisk {
    my ($dir) = @_;
    my $originalDir = getcwd();
    my $bazeliskDir = "$dir/opt/bazelisk/";

    if (-d $bazeliskDir) {
        print "Bazel dependency already exists, skipping...(`rm -rf $bazeliskDir` to rebuild)\n";
        return;
    }

    system(('bash', '-c', "tar -xzf $dir/opt/bazelisk-*.tar.gz -C $dir/opt/"));
    command_result($?, $!, 'Unpack Bazelisk...', "tar -xzf $dir/opt/bazelisk-*.tar.gz -C $dir/opt/");

    system(('bash', '-c', "mv $dir/opt/bazelisk-*/ $bazeliskDir"));
    command_result($?, $!, 'Renaming Bazelisk Dir...', "mv $dir/opt/bazelisk-*/ $bazeliskDir");

    chdir glob($bazeliskDir);

    print "\n=================================================================\n";
    print " Installing Bazelisk....\n";
    print "=================================================================\n\n";

    system('bash', '-c', 'go install github.com/bazelbuild/bazelisk@latest');
    command_result($?, $!, 'Install Bazelisk...', 'go install github.com/bazelbuild/bazelisk@latest');

    system('bash', '-c', "GOOS=linux GOARCH=amd64 go build -o $dir/bin/bazel");
    command_result($?, $!, 'Build Bazelisk...', "GOOS=linux GOARCH=amd64 go build -o $dir/bin/bazel");

    system('bash', '-c', "$dir/bin/bazel version");
    command_result($?, $!, 'Run Bazelisk...', "$dir/bin/bazel version");

    chdir $originalDir;
}

1;
