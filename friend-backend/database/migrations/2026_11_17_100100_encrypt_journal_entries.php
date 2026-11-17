<?php

use Illuminate\Contracts\Encryption\DecryptException;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;

/**
 * Journal content is now encrypted at rest. Encrypt rows written before
 * that, skipping any that already are (so re-running is safe).
 */
return new class extends Migration {
    public function up(): void
    {
        DB::table('journal_entries')->orderBy('id')->chunkById(200, function ($rows) {
            foreach ($rows as $row) {
                try {
                    Crypt::decryptString($row->content);
                    continue; // already encrypted
                } catch (DecryptException) {
                    DB::table('journal_entries')->where('id', $row->id)
                        ->update(['content' => Crypt::encryptString((string) $row->content)]);
                }
            }
        });
    }

    public function down(): void
    {
        DB::table('journal_entries')->orderBy('id')->chunkById(200, function ($rows) {
            foreach ($rows as $row) {
                try {
                    DB::table('journal_entries')->where('id', $row->id)
                        ->update(['content' => Crypt::decryptString($row->content)]);
                } catch (DecryptException) {
                }
            }
        });
    }
};
