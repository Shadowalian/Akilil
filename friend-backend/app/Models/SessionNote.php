<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SessionNote extends Model
{
    use HasFactory;

    protected $fillable = [
        'appointment_id', 'professional_user_id', 'client_user_id',
        'notes', 'action_items', 'tags',
    ];

    protected function casts(): array
    {
        return [
            'notes'         => 'encrypted',    // Task 10 at-rest
            'action_items'  => 'array',
            'tags'          => 'array',
        ];
    }

    public function appointment(): BelongsTo   { return $this->belongsTo(Appointment::class); }
    public function professional(): BelongsTo { return $this->belongsTo(User::class, 'professional_user_id'); }
    public function client(): BelongsTo       { return $this->belongsTo(User::class, 'client_user_id'); }
}