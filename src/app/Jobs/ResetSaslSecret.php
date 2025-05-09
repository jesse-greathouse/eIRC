<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable,
    Illuminate\Contracts\Queue\ShouldQueue,
    Illuminate\Foundation\Bus\Dispatchable,
    Illuminate\Queue\InteractsWithQueue,
    Illuminate\Queue\SerializesModels;

use App\Models\User,
    App\Services\NickServRegistrar;

use Exception;

class ResetSaslSecret implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected ?string $realname;

    public function __construct(?string $realname = null)
    {
        // null means “all users”
        $this->realname = $realname;
    }

    public function handle(NickServRegistrar $registrar): void
    {
        $query = User::query();

        if ($this->realname) {
            $query->where('realname', $this->realname);
        }

        foreach ($query->get() as $user) {
            // Generate a fresh SASL secret
            $newSecret = User::generateSaslSecret();

            // Ask NickServ to change its password
            $result = $registrar->changePassword($user, $newSecret);

            if (! ($result['success'] ?? false)) {
                // If it fails, abort the job with an exception
                throw new Exception(
                    "NickServ password change failed for {$user->nick}: "
                        . ($result['error'] ?? 'unknown error')
                );
            }

            // Only persist the new secret if NickServ accepted it
            $user->sasl_secret = $newSecret;
            $user->save();
        }
    }
}
