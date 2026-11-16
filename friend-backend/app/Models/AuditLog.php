<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class AuditLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'admin_id', 'action', 'subject_type', 'subject_id',
        'before', 'after', 'ip_address', 'user_agent', 'route',
    ];

    public $timestamps = false;
    protected $casts = [
        'before'     => 'array',
        'after'      => 'array',
        'created_at' => 'datetime',
    ];

    public function admin(): BelongsTo { return $this->belongsTo(User::class, 'admin_id'); }
    public function subject(): MorphTo { return $this->morphTo(); }
}