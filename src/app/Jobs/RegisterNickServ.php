<?php

namespace App\Jobs;


use Illuminate\Bus\Queueable,
    Illuminate\Contracts\Queue\ShouldQueue,
    Illuminate\Foundation\Bus\Dispatchable,
    Illuminate\Queue\InteractsWithQueue,
    Illuminate\Queue\SerializesModels;

use App\Models\User,
    App\Services\NickServRegistrar;

class RegisterNickServ implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected int $userId;

    public function __construct(int $userId)
    {
        $this->userId = $userId;
    }

    public function handle(NickServRegistrar $registrar): void
    {
        $user = User::find($this->userId);
        if (! $user) {
            return;
        }

        $result = $registrar->register($user);
        $user->is_irc_registered = $result['success'];
        $user->save();
    }
}
