<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class RatingReview extends Model
{
    use HasFactory, SoftDeletes;

    // Migration uses 'ratings_reviews' (plural 'reviews'), Laravel's default
    // convention would derive 'rating_reviews' (singular 'review'). Pin to
    // the migration's name.
    protected $table = 'ratings_reviews';

    protected $fillable = [
        'appointment_id', 'client_user_id', 'professional_user_id',
        'rating', 'comment', 'is_anonymous',
        'response_from_professional', 'response_at',
        'status',
    ];

    protected function casts(): array
    {
        return ['response_at' => 'datetime'];
    }

    public function appointment(): BelongsTo   { return $this->belongsTo(Appointment::class); }
    public function client(): BelongsTo       { return $this->belongsTo(User::class, 'client_user_id'); }
    public function professional(): BelongsTo { return $this->belongsTo(User::class, 'professional_user_id'); }
}