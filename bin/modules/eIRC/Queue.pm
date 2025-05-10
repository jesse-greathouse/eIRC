#!/usr/bin/perl

package eIRC::Queue;
use strict;
use warnings;
use File::Basename;
use Cwd qw(getcwd abs_path);;
use Exporter 'import';
use lib(dirname(abs_path(__FILE__))  . "/../modules");
use eIRC::Config qw(get_configuration);
use eIRC::Utility qw(command_result is_pid_running splash);
use Term::ANSIScreen qw(cls);

our @EXPORT_OK = qw(queue_start queue_restart queue_stop queue_kill queue_help);

warn $@ if $@; # handle exception

# Folder Paths
my $binDir = abs_path(dirname(__FILE__) . '/../../');
my $applicationRoot = abs_path(dirname($binDir));
my $srcDir = "$applicationRoot/src";
my $etcDir = "$applicationRoot/etc";
my $optDir = "$applicationRoot/opt";
my $tmpDir = "$applicationRoot/tmp";
my $varDir = "$applicationRoot/var";
my $logDir = "$varDir/log";
my $supervisorConfig = "$etcDir/supervisor/queue-manager.conf";
my $supervisorLogFile = "$logDir/queue-manager.log";
my $pidFile = "$varDir/pid/queue-manager.pid";

# Get Configuration
my %cfg = get_configuration();

# ====================================
#    Subroutines below this point
# ====================================

# ---- help text ----
sub queue_help {
    print <<'EOF';
Usage: queue [start|restart|stop|kill|help]

Manage the queue‐worker subsystem via Supervisor.

  start     — launch supervisord (queue manager) if not running, or start jobs
  restart   — restart all queue workers
  stop      — stop all queue workers
  kill      — send SIGTERM (then SIGKILL) to supervisord
  help      — this message
EOF
}

# Runs the queue manager supervisor.
sub queue_start {
    if (-e $pidFile && is_pid_running($pidFile)) {
        my @cmd = (
            'supervisorctl', '-c', $supervisorConfig,
            'start', 'all'
        );
        system(@cmd);
        command_result($?, $!, 'Start all Queue Workers...', \@cmd);
    }
    else {
        start_daemon();
    }
}

# Restarts the queue manager supervisor.
sub queue_restart {
    if (-e $pidFile && is_pid_running($pidFile)) {
        my @cmd = (
            'supervisorctl', '-c', $supervisorConfig,
            'restart', 'all'
        );
        system(@cmd);
        command_result($?, $!, 'Restart all Queue Workers...', \@cmd);
    } else {
        print "Queue Daemon not running; nothing to restart.\n";
    }
}

# Stops the queue manager supervisor.
sub queue_stop {
    if (-e $pidFile && is_pid_running($pidFile)) {
        my @cmd = (
            'supervisorctl', '-c', $supervisorConfig,
            'stop', 'all'
        );
        system(@cmd);
        command_result($?, $!, 'Stop all Queue Workers...', \@cmd);
    } else {
        print "Queue Daemon not running; nothing to stop.\n";
    }
}

# Kills the supervisor daemon (Useful to change configuration.).
# Usually you just want to stop, start, restart.
# Killing the daemon will shut off supervisor controls.
# Only use this to change a configuration file setting.
sub queue_kill {
    my $output = "Queue Daemon not found.\n";

    if (-e $pidFile && is_pid_running($pidFile)) {
        open my $fh, '<', $pidFile or die "Can't open $pidFile: $!";
        my $content = do { local $/; <$fh> };
        close $fh;

        my ($pid) = $content =~ /(\d+)/;
        if (kill 'TERM', $pid) {
            $output = "Sent SIGTERM to supervisord (PID $pid).\n";
        } else {
            warn "SIGTERM failed; trying SIGKILL...\n";
            if (kill 9, $pid) {
                $output = "Sent SIGKILL to supervisord (PID $pid).\n";
            } else {
                warn "Failed to kill PID $pid.\n";
            }
        }
    }

    print $output;
}

# Starts the supervisor daemon.
sub start_daemon {
    cls();
    splash();
    print "Starting Queue Manager Daemon...\n";

    # Export exactly the ENV vars that the supervisor conf expects
    @ENV{ qw(
        BIN DIR ETC OPT TMP VAR SRC LOG_DIR APP_NAME
    ) } = (
        $binDir,        $applicationRoot,
        $etcDir,         $cfg{queue_manager}{QUEUECTL_USER} ? () : (), # noop
        $cfg{queue_manager}{QUEUECTL_SECRET} ? () : (),                # (we only need OPT,TMP,VAR below)
        $optDir,         $tmpDir,      $varDir,
        $srcDir,         $logDir,      $cfg{laravel}{APP_NAME},
    );

    # actually start supervisord pointing at the queue config
    system('supervisord', '-c', $supervisorConfig);

    # give it a moment to spin up, then tail the log
    sleep(4);
    print_output();
}

sub print_output {
    cls();
    splash();
    system('tail', '-n', '15', $supervisorLogFile);
}

1;
