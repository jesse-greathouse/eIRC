<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory,
    Illuminate\Foundation\Auth\User as Authenticatable,
    Illuminate\Notifications\Notifiable,
    Illuminate\Support\Str;

use Laravel\Passport\HasApiTokens;

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
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    protected static function booted()
    {
        static::saving(function ($user) {
            if (empty($user->nick) && !empty($user->name)) {
                $base = Str::slug($user->name, '_'); // e.g. jesse_greathouse
                $nick = $base;
                $i = 1;

                // Ensure uniqueness by appending a suffix if necessary
                while (self::where('nick', $nick)->where('id', '!=', $user->id)->exists()) {
                    $nick = $base . '_' . $i++;
                }

                $user->nick = $nick;
            }
        });
    }
}
