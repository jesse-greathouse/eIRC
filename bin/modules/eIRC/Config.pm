#!/usr/bin/perl

package eIRC::Config;

use strict;
use warnings;
use File::Basename;
use File::Copy;
use Cwd qw(getcwd abs_path);
use Config::File qw(read_config_file);
use YAML::XS qw(LoadFile DumpFile);
use POSIX qw(strftime);
use Exporter 'import';
use lib(dirname(abs_path(__FILE__))  . "/../modules");

use eIRC::Utility qw(
    str_replace_in_file
    write_file
);

# Exported functions available for external use
our @EXPORT_OK = qw(
    get_config_file
    get_configuration
    save_configuration
    parse_env_file
    write_env_file
    write_config_file
);

warn $@ if $@; # handle exception

# Determine base paths for configuration
my $bin = abs_path(dirname(__FILE__) . '/../../');       # Path to the script's base directory
my $applicationRoot = abs_path(dirname($bin));           # Root directory of the application
my $configurationFileName = '.eirc-cfg.yml';             # Name of the config file
my $configFile = "$applicationRoot/$configurationFileName";  # Full path to the config file

# Ensure the application root directory exists before proceeding
if (! -d $applicationRoot) {
    die "Directory: \"$applicationRoot\" doesn't exist\n $!";
}

# ====================================
#    Subroutines below this point
# ====================================

# Returns the full path to the configuration file
sub get_config_file {
    return $configFile;
}

# Loads configuration from the YAML file, or creates a default config if missing
sub get_configuration {
    my %cfg;

    if (-e $configFile) {
        eval {
            my $yaml_data = LoadFile($configFile);
            %cfg = %{ $yaml_data } if ref($yaml_data) eq 'HASH';  # Ensure correct hash structure
        };
        if ($@) {
            warn "Error loading YAML file: $@. Using default values.";
            %cfg = ();  # Return an empty config if loading fails
        }
    }

    # Ensure 'meta' exists and is a proper hash
    $cfg{meta} = {} unless exists $cfg{meta} && ref($cfg{meta}) eq 'HASH';

    # Set default metadata if missing
    $cfg{meta}{created_at} //= strftime("%F %r", localtime);
    $cfg{meta}{libyaml}    //= YAML::XS::LibYAML::libyaml_version();

    # Save newly created default config if it didn't exist
    save_configuration(%cfg) unless -e $configFile;

    return %cfg;
}

# Saves the configuration hash to a YAML file, ensuring errors are caught
sub save_configuration {
    my (%cfg) = @_;

    eval {
        DumpFile($configFile, \%cfg);
    };

    if ($@) {
        die "Failed to save configuration file: $@";
    }
}

# Writes a configuration file from a template, replacing placeholders with values
sub write_config_file {
    my ($templateFile, $destinationFile, %cfg) = @_;

    # Ensure we remove the existing config file before writing a new one
    if (-e $destinationFile) {
        unlink $destinationFile or die "Failed to delete old config file: $!";
    }

    # Copy the template file to the destination before applying replacements
    copy($templateFile, $destinationFile) or die "Copy failed: $!";

    # Replace placeholders in the template with actual values
    for my $k (keys %cfg) {
        my $m = '__' . $k . '__';  # Placeholder format: __KEY__
        str_replace_in_file($m, $cfg{$k}, $destinationFile);
    }
}

# Parses an environment file and returns its key-value configuration as a hash
sub parse_env_file {
    my ($file) = @_;
    return read_config_file($file);  # Uses Config::File's read_config_file method
}

# Writes an environment file from a hash of key-value pairs
sub write_env_file {
    my ($filename, %config) = @_;

    # Remove the file if it already exists to avoid appending unwanted content
    unlink $filename if -e $filename;

    # Generate the file content efficiently
    my $content = join("\n", map { "$_=$config{$_}" } keys %config) . "\n";

    # Write the content to the file
    write_file($filename, $content);
}

1;
