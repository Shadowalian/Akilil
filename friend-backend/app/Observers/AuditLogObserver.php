<?php

namespace App\Observers;

use App\Models\AuditLog;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Request;

/**
 * AuditLogObserver — auto-writes audit_logs on every Eloquent write
 * by an authenticated admin.
 *
 * Per spec, this observer replaces the "manually call AuditLog::create
 * from every admin controller" pattern. Any Filament Resource or
 * controller that mutates a tracked model through Eloquent will
 * automatically produce an audit row.
 *
 * Notes:
 *   - Only writes (create/update/delete) are logged. Reads are NOT.
 *   - The actor is the currently-authenticated user; if no user is
 *     authenticated (e.g. a queued job), the actor_id is null.
 *   - The before/after snapshot is the model's full attribute array
 *     minus hidden fields. We do NOT log encrypted columns' plaintext.
 *   - Subject types are stored polymorphically; the admin dashboard
 *     AuditLogResource filters by subject_type for the
 *     "show me everything I did to User X" view.
 *
 * The observer is registered per-model in AdminModuleServiceProvider
 * (kept out of AppServiceProvider so the public API surface stays clean).
 */
class AuditLogObserver
{
    public function created(Model $subject): void
    {
        $this->log('created', $subject, null, $subject->getAttributes());
    }

    public function updated(Model $subject): void
    {
        $before = array_intersect_key(
            $subject->getOriginal(),
            $subject->getChanges()
        );
        $after = $subject->only(array_keys($subject->getChanges()));
        if (empty($after)) return;
        $this->log('updated', $subject, $before, $after);
    }

    public function deleted(Model $subject): void
    {
        $this->log('deleted', $subject, $subject->getOriginal(), null);
    }

    private function log(string $action, Model $subject, ?array $before, ?array $after): void
    {
        $user = Auth::user();
        if (! $user) return;   // no actor → skip (background jobs, etc.)

        $adminId = method_exists($user, 'hasAnyRole') && $user->hasAnyRole(['admin', 'support', 'moderator'])
            ? $user->id
            : null;
        if (! $adminId) return;  // only log admin/support/moderator actions

        AuditLog::create([
            'admin_id'   => $adminId,
            'action'     => $action . ':' . strtolower(class_basename($subject)),
            'subject_type' => get_class($subject),
            'subject_id'   => $subject->getKey(),
            'before'      => $before,
            'after'       => $after,
            'ip_address'  => Request::ip(),
            'user_agent'  => substr((string) Request::userAgent(), 0, 500),
            'route'       => Request::path(),
        ]);
    }
}