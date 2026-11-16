<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Gift extends Model
{
    protected $fillable = ['slug', 'name', 'emoji', 'price_cents', 'animation', 'sort_order', 'is_active'];

    protected function casts(): array
    {
        return ['price_cents' => 'integer', 'is_active' => 'boolean', 'sort_order' => 'integer'];
    }
}
