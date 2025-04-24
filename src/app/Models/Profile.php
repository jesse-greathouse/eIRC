<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Profile extends Model
{
    protected $fillable = [
        'bio',
        'timezone',
        'x_link',
        'instagram_link',
        'tiktok_link',
        'youtube_link',
        'facebook_link',
        'pinterest_link',
        'selected_avatar_id',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function avatars()
    {
        return $this->hasMany(Avatar::class);
    }

    public function selectedAvatar()
    {
        return $this->belongsTo(Avatar::class, 'selected_avatar_id');
    }
}
