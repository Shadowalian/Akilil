<?php

namespace App\Providers;

use App\Models\Appointment;
use App\Models\AuditLog;
use App\Models\CommunityChannel;
use App\Models\CommunityPost;
use App\Models\CrisisFlag;
use App\Models\JournalEntry;
use App\Models\Message;
use App\Models\ProfessionalProfile;
use App\Models\ProfessionalDocument;
use App\Models\Transaction;
use App\Models\User;
use App\Models\Vent;
use App\Observers\AuditLogObserver;
use Illuminate\Support\ServiceProvider;

/**
 * Registers Eloquent observers for the admin modules so every admin write
 * automatically produces an audit_logs row. The public-api observers
 * (JournalEntry, Vent, Message → crisis pipeline) stay in
 * AppServiceProvider for clarity.
 */
class AdminModuleServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        // Auto-audit on every admin mutation. New Filament resources
        // for these models "just work" — no per-controller log call needed.
        $models = [
            User::class,
            ProfessionalProfile::class,
            ProfessionalDocument::class,
            Appointment::class,
            CommunityChannel::class,
            CommunityPost::class,
            Transaction::class,
            CrisisFlag::class,
            Message::class,
            Vent::class,
            JournalEntry::class,
        ];
        foreach ($models as $model) {
            $model::observe(AuditLogObserver::class);
        }
    }
}