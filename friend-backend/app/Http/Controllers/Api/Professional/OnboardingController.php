<?php

namespace App\Http\Controllers\Api\Professional;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Professional\UploadDocumentRequest;
use App\Models\ProfessionalDocument;
use App\Models\ProfessionalProfile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class OnboardingController extends Controller
{
    /**
     * GET /api/professionals/onboarding/status
     * Returns the authenticated professional's onboarding summary:
     * profile state, documents uploaded, badges issued.
     */
    public function status(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403, 'Only professionals can view this.');

        $profile = $user->professionalProfile()
                        ->with(['category', 'documents'])
                        ->first();

        abort_unless($profile, 404, 'No professional profile found.');

        return response()->json([
            'profile' => [
                'id'                  => $profile->id,
                'category'            => $profile->category?->only(['id','slug','name']),
                'experience_years'    => $profile->experience_years,
                'verification_status' => $profile->verification_status,
                'badge_active'        => (bool) $profile->badge_active,
                'badge_issued_at'     => optional($profile->badge_issued_at)?->toIso8601String(),
                'is_accepting_clients' => (bool) $profile->is_accepting_clients,
            ],
            'documents' => $profile->documents->map(fn ($d) => [
                'id'              => $d->id,
                'document_type'   => $d->document_type,
                'original_filename'=> $d->original_filename,
                'size_bytes'      => $d->size_bytes,
                'review_status'   => $d->review_status,
                'reviewed_at'     => optional($d->reviewed_at)?->toIso8601String(),
                'created_at'      => optional($d->created_at)?->toIso8601String(),
            ]),
            'progress' => [
                'profile_complete'   => ! empty($profile->bio) && $profile->experience_years > 0,
                'documents_uploaded' => $profile->documents->count() > 0,
                'badge_active'       => (bool) $profile->badge_active,
                'can_start_sessions' => (bool) $profile->is_accepting_clients,
            ],
            'next_step' => match (true) {
                ! $profile->bio                       => 'complete_bio',
                $profile->documents->isEmpty()         => 'upload_documents',
                $profile->verification_status === 'pending'   => 'awaiting_review',
                $profile->verification_status === 'rejected' => 'fix_rejection',
                default => 'onboarded',
            },
        ]);
    }

    /**
     * POST /api/professionals/onboarding/documents
     * Multipart file upload (stored on PRIVATE_DISK, never public).
     */
    public function upload(UploadDocumentRequest $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403, 'Only professionals can upload documents.');

        $file = $request->file('file');
        $path = $file->store(
            "professionals/{$user->id}/documents",
            ['disk' => config('filesystems.private_disk', 'local')]
        );

        $doc = ProfessionalDocument::create([
            'user_id'           => $user->id,
            'document_type'     => $request->string('document_type')->toString(),
            'file_path'         => $path,
            'original_filename' => $file->getClientOriginalName(),
            'size_bytes'        => $file->getSize(),
            'mime_type'         => $file->getMimeType() ?? 'application/octet-stream',
            'description'       => $request->input('description'),
            'review_status'     => 'pending',
        ]);

        return response()->json([
            'id'              => $doc->id,
            'document_type'   => $doc->document_type,
            'original_filename'=> $doc->original_filename,
            'review_status'   => $doc->review_status,
            'created_at'      => $doc->created_at->toIso8601String(),
        ], 201);
    }

    /**
     * DELETE /api/professionals/onboarding/documents/{id}
     * Removes a document (only if status is still 'pending' — you can't
     * pull a doc after admin review without an admin action).
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $doc = ProfessionalDocument::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();
        abort_if($doc->review_status !== 'pending', 422, 'Cannot remove a document that has been reviewed.');

        Storage::disk(config('filesystems.private_disk', 'local'))->delete($doc->file_path);
        $doc->delete();
        return response()->json(['message' => 'Document removed.']);
    }
}