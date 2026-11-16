<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\ProfessionalDocument;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class MediaController extends Controller
{
    /**
     * GET /api/media/{path}
     * Serves files from PRIVATE_DISK. A file is only readable by the user
     * who owns it (own folder or own professional_documents row); admins and
     * support can read anything, but every such read is audited.
     */
    public function show(Request $request, string $path): StreamedResponse
    {
        $user = $request->user();
        abort_unless($user, 401);

        $disk = Storage::disk(config('filesystems.private_disk', 'local'));
        abort_unless($disk->exists($path), 404);

        $document = ProfessionalDocument::where('file_path', $path)->first();

        $isOwner = str_starts_with($path, "professionals/{$user->id}/")
            || ($document && (int) $document->user_id === (int) $user->id);
        $isStaff = method_exists($user, 'hasAnyRole') && $user->hasAnyRole(['admin', 'support']);

        abort_unless($isOwner || $isStaff, 403, 'Not your file.');

        if (! $isOwner) {
            $this->audit($request, $user, $path, $document);
        }

        return $disk->response($path);
    }

    /**
     * Staff reads of someone else's file leave an audit trail. The subject is
     * the document row when we have one, otherwise the user the path belongs to.
     */
    private function audit(Request $request, User $staff, string $path, ?ProfessionalDocument $document): void
    {
        $subject = $document ?: $this->pathOwner($path) ?: $staff;

        AuditLog::create([
            'admin_id'     => $staff->id,
            'action'       => 'media:read',
            'subject_type' => get_class($subject),
            'subject_id'   => $subject->getKey(),
            'before'       => null,
            'after'        => ['path' => $path],
            'ip_address'   => $request->ip(),
            'user_agent'   => substr((string) $request->userAgent(), 0, 500),
            'route'        => $request->path(),
        ]);
    }

    private function pathOwner(string $path): ?User
    {
        if (! preg_match('#^professionals/(\d+)/#', $path, $m)) {
            return null;
        }
        return User::find((int) $m[1]);
    }
}
