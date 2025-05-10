<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

use App\Models\User,
    App\Services\NickServRegistrar;

class NickServRegisterUser extends Command
{
    protected $signature = 'eirc:nickserv-register-user {realname}';
    protected $description = 'Register a single user with NickServ by realname';

    public function handle(NickServRegistrar $registrar): int
    {
        $realname = $this->argument('realname');
        $user = User::where('realname', $realname)->first();

        if (! $user) {
            $this->error("No user found with realname '{$realname}'.");
            return 1;
        }

        $this->info("Registering {$user->nick}…");
        $result = $registrar->register($user);

        if ($result['success']) {
            $user->is_irc_registered = true;
            $user->save();

            $this->info("Success! IRC responded:");
            foreach ($result['responses'] as $line) {
                $this->line("  → {$line}");
            }
            return 0;
        }

        $this->error("Registration failed: {$result['error']}");
        return 1;
    }
}
