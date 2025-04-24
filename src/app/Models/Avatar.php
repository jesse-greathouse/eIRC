<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Avatar extends Model
{
    protected $fillable = [
        'base64_data',
    ];

    public function profile()
    {
        return $this->belongsTo(Profile::class);
    }
}
