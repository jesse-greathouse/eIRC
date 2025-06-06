<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory,
    Illuminate\Foundation\Auth\User as Authenticatable,
    Illuminate\Notifications\Notifiable,
    Illuminate\Support\Str;

use Laravel\Passport\HasApiTokens;

use App\Jobs\RegisterNickServ;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'nick',
        'settings',
        'channels',
        'sasl_secret',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at'     => 'datetime',
            'password'              => 'hashed',
            'settings'              => 'array',
            'is_irc_registered'     => 'boolean',
        ];
    }

    /**
     * Generate a strong random secret.
     */
    public static function generateSaslSecret(): string
    {
        // NickServ passwords must be ≤ 32 chars
        return Str::random(32);
    }

    public function profile()
    {
        return $this->hasOne(Profile::class);
    }

    protected static function booted()
    {
        static::creating(function ($user) {
            if (empty($user->sasl_secret)) {
                $user->sasl_secret = self::generateSaslSecret();
            }
        });

        static::created(function (User $user) {
            RegisterNickServ::dispatch($user->id)
                ->onConnection('irc_operations')
                ->onQueue('irc_operations');
        });

        static::saving(function ($user) {
            if (!empty($user->name)) {
                $base = Str::slug($user->name, '_'); // e.g. jesse_greathouse

                // Assign realname only if it's not set (realname is permanent)
                if (empty($user->realname)) {
                    $realname = $base;
                    $j = 1;

                    // Ensure uniqueness for realname
                    while (self::where('realname', $realname)->where('id', '!=', $user->id)->exists()) {
                        $realname = $base . '_' . $j++;
                    }

                    $user->realname = $realname;
                }

                if (empty($user->nick)) {
                    $user->nick = $base;
                }

            }
        });
    }
}
