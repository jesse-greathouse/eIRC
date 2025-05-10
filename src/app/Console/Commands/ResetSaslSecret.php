<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

use App\Jobs\ResetSaslSecret as ResetSaslSecretJob;

class ResetSaslSecret extends Command
{
    protected $signature = 'eirc:reset-sasl-secret {realname?}';
    protected $description = 'Reset SASL secret for one user (by realname) or all if omitted';

    public function handle(): int
    {
        $realname = $this->argument('realname'); // null if missing

        if ($realname) {
            $this->info("Resetting SASL secret for user '{$realname}'...");
        } else {
            $this->info("Resetting SASL secret for ALL users...");
        }

        // Dispatch the queued job
        ResetSaslSecretJob::dispatch($realname);

        $this->info("Job queued. It will run on the `default` queue.");
        return 0;
    }
}
