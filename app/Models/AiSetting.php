<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;

class AiSetting extends Model
{
    protected $fillable = ['setting', 'value', 'user_id'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
