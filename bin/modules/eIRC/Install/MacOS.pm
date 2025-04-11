#!/usr/bin/perl

package eIRC::Install::MacOS;
use strict;
use Cwd qw(getcwd abs_path);
use Env;
use File::Basename;
use POSIX qw(uname);
use lib dirname(abs_path(__FILE__)) . "/modules";
use eIRC::Utility qw(command_result);
use eIRC::System qw(how_many_threads_should_i_use);
use Exporter 'import';

our @EXPORT_OK = qw(install_system_dependencies install_php install_bazelisk);

my $bin = abs_path(dirname(__FILE__) . '/../../../');
my $applicationRoot = abs_path(dirname($bin));
my @systemDependencies = qw(
    intltool autoconf automake expect gcc pcre2 curl libiconv pkg-config
    openssl@3.0 mysql-client oniguruma libxml2 icu4c imagemagick mysql
    libsodium libzip glib webp go cpanminus
);

# ====================================
# Subroutines
# ====================================

# Installs OS level system dependencies.
sub install_system_dependencies {
    print "Brew is required for updating and installing system dependencies.\n";

    # Update/Upgrade Homebrew
    system('brew', 'upgrade');
    command_result($?, $!, "Updated system dependencies...");

    # Filter system dependencies to only install what's missing
    my @to_install;
    foreach my $pkg (@systemDependencies) {
        my $check = system("brew list $pkg > /dev/null 2>&1");
        if ($check != 0) {
            push @to_install, $pkg;
        } else {
            print "✓ $pkg already installed, skipping.\n";
        }
    }

    # Install only what's needed
    if (@to_install) {
        system('brew', 'install', @to_install);
        command_result($?, $!, "Installed missing dependencies...", 'brew install', @to_install);
    } else {
        print "All system dependencies already installed.\n";
    }

    install_pip();
    install_supervisor();
}

# Installs PHP.
sub install_php {
    my ($dir) = @_;
    my $threads = how_many_threads_should_i_use();

    $ENV{'PKG_CONFIG_PATH'} = '/usr/local/opt/icu4c/lib/pkgconfig';

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
        '--with-iconv=/usr/local/opt/libiconv'
    );

    my $originalDir = getcwd();

    # Unpack PHP Archive
    system('bash', '-c', "tar -xzf $dir/opt/php-*.tar.gz -C $dir/opt/");
    command_result($?, $!, 'Unpacked PHP Archive...', 'tar -xf ' . $dir . '/opt/php-*.tar.gz -C ' . $dir . '/opt/');

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
    command_result($?, $!, 'Compile PHP...', "make -j$threads";

    system('make install');
    command_result($?, $!, 'Installed PHP...', 'make install');

    chdir $originalDir;
}

# Installs Pip if not already installed.
sub install_pip {
    # Check if pip is already available
    my $pipStatus = `python3 -m pip --version 2>&1`;
    if ($? == 0 && $pipStatus =~ /^pip\s+\d+\./) {
        print "✓ Pip already installed: $pipStatus";
        return;
    }

    print "Installing pip using get-pip.py...\n";

    my $pipInstallScript = 'get-pip.py';
    system("curl -sS https://bootstrap.pypa.io/$pipInstallScript -o $pipInstallScript");
    command_result($?, $!, "Downloaded pip installer...");

    system("chmod +x $pipInstallScript");
    command_result($?, $!, "Made pip installer executable...");

    system("python3 $pipInstallScript");
    command_result($?, $!, "Installed pip...");

    unlink($pipInstallScript);
}

# Installs Supervisor using pip, if not already installed.
sub install_supervisor {
    my $check = system('python3', '-m', 'pip', 'show', 'supervisor') == 0;

    if ($check) {
        print "✓ Supervisor already installed (via pip), skipping.\n";
        return;
    }

    print "Installing Supervisor via pip...\n";
    system('python3', '-m', 'pip', 'install', 'supervisor');
    command_result($?, $!, "Installed Supervisor...", 'python3', '-m', 'pip', 'install', 'supervisor');
}

# installs Bazelisk.
sub install_bazelisk {
    my ($dir) = @_;
    my ($sysname, $nodename, $release, $version, $machine) = uname();
    my $arch = ($machine eq 'arm64') ? 'arm64' : 'amd64';
    my $originalDir = getcwd();
    my $bazeliskDir = "$dir/opt/bazelisk/";

    # If elixir directory exists, delete it.
    if (-d $bazeliskDir) {
        system(('bash', '-c', "rm -rf $bazeliskDir"));
        command_result($?, $!, "Removing existing Bazelisk directory...", "rm -rf $bazeliskDir");
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
    my $buildCmd = "GOOS=darwin GOARCH=$arch go build -o $dir/bin/bazel";
    system('bash', '-c', $buildCmd);
    command_result($?, $!, 'Build Bazelisk...', $buildCmd);

    system('bash', '-c', "$dir/bin/bazel version");
    command_result($?, $!, 'Run Bazelisk...', "$dir/bin/bazel version");

    chdir $originalDir;
}

1;
