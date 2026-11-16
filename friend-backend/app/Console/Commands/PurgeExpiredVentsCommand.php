<?php

namespace App\Console\Commands;

use App\Models\Vent;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

/**
 * friend:vents:purge-expired
 * Soft-purges vents whose expires_at is in the past. The voice_path file
 * (if any) is removed from PRIVATE_DISK.
 *
 * Schedule: every 5 minutes via routes/console.php.
 */
class PurgeExpiredVentsCommand extends Command
{
    protected $signature = 'friend:vents:purge-expired {--dry-run : Print what would be deleted}';
    protected $description = 'Soft-delete vents whose expires_at has passed and remove their voice files.';

    public function handle(): int
    {
        $now = now();
        $expired = Vent::whereNotNull('expires_at')
            ->where('expires_at', '<', $now)
            ->get();

        if ($expired->isEmpty()) {
            $this->info('No expired vents.');
            return self::SUCCESS;
        }

        foreach ($expired as $vent) {
            $this->line("Purging vent #{$vent->id} (expired {$vent->expires_at->diffForHumans()})");
            if ($this->option('dry-run')) continue;

            if ($vent->voice_path) {
                Storage::disk(config('filesystems.private_disk', 'local'))->delete($vent->voice_path);
            }
            $vent->delete();    // soft delete via model SoftDeletes trait
        }

        $this->info("Purged {$expired->count()} vents.");
        return self::SUCCESS;
    }
}