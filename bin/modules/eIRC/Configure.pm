#!/usr/bin/perl

package eIRC::Configure;

use strict;
use warnings;
use File::Basename;
use File::Touch;
use Cwd qw(getcwd abs_path);
use List::Util 1.29 qw(pairs);
use Exporter 'import';
use Scalar::Util qw(looks_like_number);
use Term::Prompt;
use Term::Prompt qw(termwrap);
use Term::ANSIScreen qw(cls);
use lib(dirname(abs_path(__FILE__)) . "/../modules");
use eIRC::Config qw(
    get_config_file
    get_configuration
    save_configuration
    parse_env_file
    write_env_file
    write_config_file
);
use eIRC::Migrate qw(migrate);
use eIRC::Seed qw(seed);
use eIRC::PassportKeys qw(passport_keys);
use eIRC::Utility qw(splash generate_rand_str write_file);

our @EXPORT_OK = qw(configure configure_help);

warn $@ if $@; # handle exception

# ------------------------
# Define Global Variables
# ------------------------

# Define important application directories
my $binDir = abs_path(dirname(__FILE__) . '/../../');
my $applicationRoot = abs_path(dirname($binDir));
my $srcDir = "$applicationRoot/src";
my $webDir = "$srcDir/public";
my $varDir = "$applicationRoot/var";
my $logDir = "$varDir/log";
my $optDir = "$applicationRoot/opt";
my $etcDir = "$applicationRoot/etc";
my $tmpDir = "$applicationRoot/tmp";
my $uploadDir = "$varDir/upload";
my $cacheDir = "$varDir/cache";
my $downloadDir = "$varDir/download";

# Files
my $laravelEnvFile = "$applicationRoot/src/.env";
my $errorLog = "$logDir/error.log";
my $sslCertificate = "$etcDir/ssl/certs/eirc.cert";
my $sslKey = "$etcDir/ssl/private/eirc.key";

# Default Supervisor control ports
my $supervisorPort = 5959;
my $queueCtlPort = 5960;

# Generate an application key and secret for authentication
my $appKey = generate_app_key();
my $secret = generate_rand_str();

# Default configuration values
my %cfg = get_configuration();

# List of configuration files to be written
my %config_files = (
    initd               => ["$etcDir/init.d/init-template.sh.dist",             "$etcDir/init.d/eirc"],
    php_fpm             => ["$etcDir/php-fpm.d/php-fpm.dist.conf",              "$etcDir/php-fpm.d/php-fpm.conf"],
    force_ssl           => ["$etcDir/nginx/force-ssl.dist.conf",                "$etcDir/nginx/force-ssl.conf"],
    ssl_params          => ["$etcDir/nginx/ssl-params.dist.conf",               "$etcDir/nginx/ssl-params.conf"],
    openssl             => ["$etcDir/ssl/openssl.dist.cnf",                     "$etcDir/ssl/openssl.cnf"],
    nginx               => ["$etcDir/nginx/nginx.dist.conf",                    "$etcDir/nginx/nginx.conf"],
    supervisord         => ["$etcDir/supervisor/conf.d/supervisord.conf.dist",  "$etcDir/supervisor/conf.d/supervisord.conf"],
    queue_manager       => ["$etcDir/supervisor/queue-manager.conf.dist",       "$etcDir/supervisor/queue-manager.conf"],
);

my %defaults = (
    laravel => {
        APP_NAME                    => 'eirc',
        VITE_APP_NAME               => 'eirc',
        APP_ENV                     => 'local',
        APP_KEY                     => $appKey,
        APP_DEBUG                   => 'true',
        DB_CONNECTION               => 'mysql',
        DB_HOST                     => '127.0.0.1',
        DB_PORT                     => '3306',
        DB_DATABASE                 => 'eirc',
        DB_USERNAME                 => 'eirc',
        DB_PASSWORD                 => 'eirc',
        CACHE_DRIVER                => 'file',
        SESSION_DRIVER              => 'cookie',
        QUEUE_CONNECTION            => 'database',
        APP_URL                     => 'http://localhost:8181',
        LOG_SLACK_WEBHOOK_URL       => 'none',
        SESSION_DOMAIN              => 'localhost',
        SANCTUM_STATEFUL_DOMAINS    => 'localhost',
        APP_TIMEZONE                => 'UTC',
        LOG_CHANNEL                 => 'stack',
        LOG_DIR                     => $logDir,
        DOWNLOAD_DIR                => $downloadDir,
        CACHE_DIR                   => $cacheDir,
        REDIS_CLIENT                => 'phpredis',
    },
    nginx => {
        DOMAINS                     => '127.0.0.1',
        IS_SSL                      => 'no',
        PORT                        => '8181',
        SSL_CERT                    => $sslCertificate,
        SSL_KEY                     => $sslKey,
    },
    redis => {
        REDIS_HOST                  => '/var/run/redis/redis.sock',
        REDIS_PORT                  => '0',
        REDIS_PASSWORD              => 'null',
        REDIS_DB                    => '0',
    },
);

# ====================================
#    Subroutines below this point
# ====================================

# Displays help for configure options.
sub configure_help {
    print <<'EOF';
Usage: configure [--option]

Sets up the eIRC configuration system. By default, the script runs in interactive mode.

Examples:
  configure                   # Run interactive configuration
  configure --non-interactive # Run non-interactive mode using default or pre-defined values

 Available options:
  --non-interactive   Skip all interactive prompts (for automation)
  help                Show this help message

EOF
}

# Runs the main configuration routine.
# This function is executed when the script is run.
sub configure {
    my ($interactive_mode) = @_;
    $interactive_mode = 1 unless defined $interactive_mode;

    if ($interactive_mode) {
        cls();
        splash();
        print "\n=================================================================\n";
        print " This will create the eIRC configuration\n";
        print "=================================================================\n\n";

        request_user_input();
    }

    merge_defaults();
    assign_dynamic_config();
    save_configuration(%cfg);

    # Refreshes the cfg variable with exactly what was just written to the file.
    my %liveCfg = get_configuration();

    # Write configuration files
    foreach my $key (keys %config_files) {
        write_config(@{$config_files{$key}}, $liveCfg{$key} // {});
    }

    write_laravel_env();

    if ($interactive_mode) {
        prompt_migrate();
        prompt_seed();
        prompt_change_encryption_keys();
    } else {
        print "\nConfiguration completed in non-interactive mode.\n";
        print "Note: If this is a fresh install, be sure to manually run the following commands as needed:\n";
        print "  bin/migrate         # Run database migrations\n";
        print "  bin/seed            # Seed the database with default values\n";
        print "  bin/passport-keys   # Generate Laravel Passport encryption keys\n\n";
    }
}

# Generates a Laravel application key if none exists.
# This is required for encrypting secure application data.
sub generate_app_key {
    # Laravel needs an .env file with this empty APP_KEY to encrypt a key with the console.
    unless (-e $laravelEnvFile) {
        open my $fh, '>', $laravelEnvFile or die "Cannot create $laravelEnvFile: $!";
        print $fh "APP_KEY=";
        close $fh;
    }
    return `$binDir/php $srcDir/artisan key:generate`;
}

# Writes a configuration file from its template.
sub write_config {
    my ($distFile, $outFile, $config_ref) = @_;
    return unless -e $distFile;
    write_config_file($distFile, $outFile, %$config_ref);
    chmod 0755, $outFile if $outFile =~ /init/;
}

# Writes Laravel's environment configuration file.
sub write_laravel_env {
    write_env_file($laravelEnvFile, %{$cfg{laravel}});  # Dereference the hash reference
}

# Merges Laravel-specific environment variables from an existing .env file.
sub merge_laravel_env {
    if (-e $laravelEnvFile) {
        my $env = parse_env_file($laravelEnvFile);
        $cfg{laravel}{$_} = $env->{$_} for keys %$env;
        save_configuration(%cfg);
    }
}

# Runs interactive prompts to collect user configuration input.
sub request_user_input {
    merge_laravel_env();

    # Define the exact order for user input prompts with human-readable names
    my @ordered_keys = (
        # Laravel settings
        ['laravel', 'APP_NAME', 'App Name'],
        ['laravel', 'VITE_APP_NAME', 'Vite App Name'],
        ['laravel', 'APP_ENV', 'Application Environment'],
        ['laravel', 'APP_KEY', 'Application Key'],
        ['laravel', 'APP_DEBUG', 'Enable Debugging'],
        ['laravel', 'DB_CONNECTION', 'Database Connection Type'],
        ['laravel', 'DB_HOST', 'Database Host'],
        ['laravel', 'DB_PORT', 'Database Port'],
        ['laravel', 'DB_DATABASE', 'Database Name'],
        ['laravel', 'DB_USERNAME', 'Database Username'],
        ['laravel', 'DB_PASSWORD', 'Database Password'],
        ['laravel', 'CACHE_DRIVER', 'Cache Driver'],
        ['laravel', 'SESSION_DRIVER', 'Session Driver'],
        ['laravel', 'QUEUE_CONNECTION', 'Queue Connection Type'],
        ['laravel', 'APP_URL', 'Application URL'],
        ['laravel', 'LOG_SLACK_WEBHOOK_URL', 'Log Slack Webhook URL'],
        ['laravel', 'SESSION_DOMAIN', 'Session Domain'],
        ['laravel', 'SANCTUM_STATEFUL_DOMAINS', 'Sanctum Stateful Domains'],
        ['laravel', 'APP_TIMEZONE', 'Application Timezone'],
        ['laravel', 'LOG_CHANNEL', 'Log Channel'],
        ['laravel', 'LOG_DIR', 'Log Directory'],
        ['laravel', 'DOWNLOAD_DIR', 'Download Directory'],
        ['laravel', 'CACHE_DIR', 'Cache Directory'],
        ['laravel', 'REDIS_CLIENT', 'Redis Client'],

        # Nginx settings
        ['nginx', 'DOMAINS', 'Server Domains (Comma-separated)'],
        ['nginx', 'IS_SSL', 'Enable SSL (HTTPS)'],
        ['nginx', 'PORT', 'Web Server Port'],
        ['nginx', 'SSL_CERT', 'SSL Certificate Path'],
        ['nginx', 'SSL_KEY', 'SSL Key Path'],

        # Redis settings
        ['redis', 'REDIS_HOST', 'Redis Host'],
        ['redis', 'REDIS_PORT', 'Redis Port'],
        ['redis', 'REDIS_PASSWORD', 'Redis Password'],
        ['redis', 'REDIS_DB', 'Redis Database Index'],
    );

    # Prompt the user in the exact order defined above
    foreach my $pair (@ordered_keys) {
        my ($domain, $key, $prompt_text) = @$pair; # Extract human-readable prompt name

        if ($key =~ /DEBUG|IS_SSL/) {
            input_boolean($domain, $key, $prompt_text);
        } elsif ($key =~ /PORT$/) {
            input_integer($domain, $key, $prompt_text);
        } else {
            input($domain, $key, $prompt_text);
        }
    }
}

# Merges default values into the configuration hash (%cfg) for any keys that are not already set.
# This ensures that each configuration setting has a value, either from user input or the predefined defaults.
# It iterates over the %defaults hash, checking each domain and its respective keys,
# and assigns the default value to %cfg only if the key doesn't already have a value.
#
# Example:
# If %defaults contains a default value for 'APP_NAME' under the 'laravel' domain,
# and $cfg{laravel}{APP_NAME} is not set, it will assign $cfg{laravel}{APP_NAME} the value from %defaults.
sub merge_defaults {
    foreach my $domain (keys %defaults) {
        foreach my $key (keys %{$defaults{$domain}}) {
            $cfg{$domain}{$key} //= $defaults{$domain}{$key};
        }
    }
}

# This subroutine assigns dynamically generated values to the %cfg configuration hash.
# Unlike merge_defaults(), which ensures missing values are filled from predefined defaults,
# this subroutine handles values that depend on runtime conditions, environment variables,
# or logic based on other configuration settings.
#
# Some component configurations depend on the same environment strings that are defined by others.
# This sub can handle setting ENV variables that are mirrored in other components.
#
# - Supervisor, Instance Manager, and Queue Manager Users/Secrets:
#   - Assigns the current system username ($ENV{"LOGNAME"}) to the respective control users.
#   - Generates and assigns a random secret string for authentication if not already set.
#
# - SSL Configuration:
#   - If 'IS_SSL' is set to 'true', it:
#     - Configures SSL settings for Nginx.
#     - Sets the web server port to '443' (default for HTTPS).
#     - Assigns paths for SSL certificate and key.
#     - Ensures the Nginx configuration includes the force-SSL directive.
#   - If 'IS_SSL' is 'false', it:
#     - Clears SSL-related configuration values.
#     - Ensures Nginx does not enforce HTTPS.
#
# This subroutine ensures that all required runtime-dependent configurations
# are applied correctly before writing them to configuration files.
sub assign_dynamic_config {
    # Ensure SANCTUM_STATEFUL_DOMAINS is set based on SESSION_DOMAIN or APP_URL
    $cfg{laravel}{SANCTUM_STATEFUL_DOMAINS} //=
        $cfg{laravel}{SESSION_DOMAIN} // $cfg{laravel}{APP_URL};

    # Ensure VITE_APP_NAME is the same as APP_NAME if not explicitly set
    $cfg{laravel}{VITE_APP_NAME} //= $cfg{laravel}{APP_NAME};

    # Ensure Laravel-specific paths and settings
    $cfg{laravel}{LOG_URI} //= $errorLog;
    $cfg{laravel}{DOWNLOAD_DIR} //= $downloadDir;
    $cfg{laravel}{CACHE_DIR} //= $cacheDir;
    $cfg{laravel}{LOG_DIR} //= $logDir;

    # Redis configuration inheritance for Laravel
    $cfg{laravel}{REDIS_HOST} //= $cfg{redis}{REDIS_HOST} // $defaults{redis}{REDIS_HOST};
    $cfg{laravel}{REDIS_PORT} //= $cfg{redis}{REDIS_PORT} // $defaults{redis}{REDIS_PORT};
    $cfg{laravel}{REDIS_PASSWORD} //= $cfg{redis}{REDIS_PASSWORD} // $defaults{redis}{REDIS_PASSWORD};
    $cfg{laravel}{REDIS_DB} //= $cfg{redis}{REDIS_DB} // $defaults{redis}{REDIS_DB};

    # Initd configuration values.
    $cfg{initd}{APP_NAME} //= $cfg{laravel}{APP_NAME};
    $cfg{initd}{DIR} //= $applicationRoot;

    # php-fpm configuration values.
    $cfg{php_fpm}{DIR} //= $applicationRoot;
    $cfg{php_fpm}{APP_NAME} //= $cfg{laravel}{APP_NAME};
    $cfg{php_fpm}{USER} //= $ENV{"LOGNAME"};

    # Ensure Nginx configuration consistency
    $cfg{nginx}{DOMAINS} //= $cfg{laravel}{SESSION_DOMAIN};
    $cfg{nginx}{LOG} //= $errorLog;
    $cfg{nginx}{DIR} //= $applicationRoot;
    $cfg{nginx}{BIN} //= $binDir;
    $cfg{nginx}{VAR} //= $varDir;
    $cfg{nginx}{ETC} //= $etcDir;
    $cfg{nginx}{OPT} //= $optDir;
    $cfg{nginx}{WEB} //= "$applicationRoot/src/public";
    $cfg{nginx}{SRC} //= "$applicationRoot/src";

    # Ensure security configurations
    $cfg{nginx}{SESSION_SECRET} //= $secret;
    $cfg{nginx}{USER} //= $ENV{"LOGNAME"};

    # Handle SSL-specific configuration
    if ($cfg{nginx}{IS_SSL} eq 'true') {
        $cfg{nginx}{SSL} = 'ssl http2';
        $cfg{nginx}{PORT} = '443';
        $cfg{nginx}{SSL_CERT_LINE} = 'ssl_certificate ' . $cfg{nginx}{SSL_CERT};
        $cfg{nginx}{SSL_KEY_LINE} = 'ssl_certificate_key ' . $cfg{nginx}{SSL_KEY};
        $cfg{nginx}{INCLUDE_FORCE_SSL_LINE} = "include $etcDir/nginx/force-ssl.conf";
    } else {
        $cfg{nginx}{SSL} = '';
        $cfg{nginx}{SSL_CERT_LINE} = '';
        $cfg{nginx}{SSL_KEY_LINE} = '';
        $cfg{nginx}{INCLUDE_FORCE_SSL_LINE} = '';
    }

    # force ssl configuration values.
    $cfg{force_ssl}{DOMAINS} //= $cfg{nginx}{DOMAINS};

    # ssl params configuration values.
    $cfg{ssl_params}{ETC} //= $etcDir;

    # openssl configuration values.
    $cfg{openssl}{ETC} //= $etcDir;

    # Assign dynamically generated values that are not part of %defaults
    $cfg{supervisord}{SUPERVISORCTL_USER} //= $ENV{"LOGNAME"};
    $cfg{supervisord}{SUPERVISORCTL_SECRET} //= $secret;

    $cfg{queue_manager}{QUEUECTL_USER} //= $ENV{"LOGNAME"};
    $cfg{queue_manager}{QUEUECTL_SECRET} //= $secret;
    $cfg{queue_manager}{RABBITMQ_PORT} //= $cfg{queue_manager}{RABBITMQ_PORT} // $cfg{rabbitmq}{RABBITMQ_PORT};
    $cfg{queue_manager}{RABBITMQ_NODENAME} //= $cfg{queue_manager}{RABBITMQ_NODENAME} // $cfg{rabbitmq}{RABBITMQ_NODENAME};

    # Assign dynamic Supervisor and Queue ports
    $cfg{supervisord}{SUPERVISORCTL_PORT} //= $supervisorPort;
    $cfg{queue_manager}{QUEUECTL_PORT} //= $queueCtlPort;
}

sub input {
    my ($varDomain, $varName, $promptText) = @_;

    # Retrieve default value from %cfg or %defaults
    my $default = $cfg{$varDomain}{$varName} // $defaults{$varDomain}{$varName} // '';

    # Prompt the user
    my $answer = prompt('x', "$promptText:", '', $default);

    # Special case: Ensure Nginx server_name domains are space-separated, not comma-separated
    if ($varDomain eq 'nginx' && $varName eq 'DOMAINS') {
        $answer =~ s/,/ /g;  # Replace all commas with spaces
        $answer =~ s/\s+/ /g; # Remove extra spaces
        $answer =~ s/^\s+|\s+$//g; # Trim leading/trailing spaces
    }

    # Store the user-provided or default value
    $cfg{$varDomain}{$varName} = $answer;
}

# Prompts for boolean (yes/no) input.
sub input_boolean {
    my ($varDomain, $varName, $promptText) = @_;

    # Ensure default value is correctly retrieved
    my $default_value = $cfg{$varDomain}{$varName} // $defaults{$varDomain}{$varName} // 'false';

    # Convert 'true'/'false' to 'yes'/'no' for user-friendly display
    my $default = ($default_value eq 'true') ? 'yes' : 'no';

    # Prompt the user
    my $answer = prompt('y', "$promptText:", '', $default);

    # Store 'true' or 'false' based on input
    $cfg{$varDomain}{$varName} = ($answer eq 'yes') ? 'true' : 'false';
}

# Prompts for integer input with validation.
sub input_integer {
    my ($varDomain, $varName, $promptText) = @_;
    my $default = $cfg{$varDomain}{$varName} // $defaults{$varDomain}{$varName};
    while (1) {
        my $answer = prompt('x', "$promptText (integer required):", '', $default);
        if ($answer =~ /^\d+$/) {
            $cfg{$varDomain}{$varName} = $answer;
            last;
        }
        print "Invalid input. Please enter a valid integer.\n";
    }
}

# Displays a prompt to the user asking whether to run database migrations.
sub prompt_migrate {
    print "\n=================================================================\n";
    print " Database Migrations\n";
    print "=================================================================\n\n";

    print "Now that your database is configured, you may update the schema to the latest design.\n";
    print "This will apply all pending migrations.\n\n";
    print "You can also run this manually later using: bin/migrate\n\n";

    my $answer = prompt('y', "Run Database Migrations?", '', "y");

    if ($answer eq 1) {
        migrate();
    }
}

# Displays a prompt to the user asking whether to seed the database with default values.
sub prompt_seed {
    print "\n=================================================================\n";
    print " Seed Default Data\n";
    print "=================================================================\n\n";

    print "Seed the database with default values such as roles, permissions, and initial settings.\n";
    print "Recommended after a fresh migration.\n\n";
    print "You can also run this manually later using: bin/seed\n\n";

    my $answer = prompt('y', "Seed the Database?", '', "y");

    if ($answer eq 1) {
        seed();
    }
}

# Displays a prompt to the user asking whether to generate passport encryption keys.
sub prompt_change_encryption_keys {
    print "\n=================================================================\n";
    print " Generate Encryption Keys\n";
    print "=================================================================\n\n";

    print "Encryption keys are required to issue secure access tokens.\n";
    print "Warning: This will reset all existing logins and invalidate all API tokens.\n\n";
    print "You can also run this manually later using: bin/passport-keys\n\n";

    my $answer = prompt('y', "Generate Laravel Passport Encryption Keys?", '', "y");

    if ($answer eq 1) {
        passport_keys();
    }
}


1;
