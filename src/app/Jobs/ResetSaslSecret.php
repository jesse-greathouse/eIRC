<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable,
    Illuminate\Contracts\Queue\ShouldQueue,
    Illuminate\Foundation\Bus\Dispatchable,
    Illuminate\Queue\InteractsWithQueue,
    Illuminate\Queue\SerializesModels;

use App\Models\User;

class ResetSaslSecret implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected ?string $realname;

    public function __construct(?string $realname = null)
    {
        // null means “all users”
        $this->realname = $realname;
    }

    public function handle(): void
    {
        $query = User::query();

        if ($this->realname) {
            $query->where('realname', $this->realname);
        }

        foreach ($query->get() as $user) {
            // Generate new secret
            $user->sasl_secret = User::generateSaslSecret();

            // TODO: synchronize this user’s new SASL secret with NickServ

            $user->save();
        }
    }
}
