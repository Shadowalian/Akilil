<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Auth\VerifyEmailRequest;
use Illuminate\Auth\Events\Verified;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EmailVerificationController extends Controller
{
    /**
     * POST /api/auth/verify-email
     * Body: { id, hash, expires, signature }
     *
     * Signed URL mirrors Laravel's built-in verification route's
     * query-string format; Task 7's User app will hit a deep-link
     * that forwards these params here.
     */
    public function verify(VerifyEmailRequest $request): JsonResponse
    {
        if (! hash_equals(sha1($request->user()->getEmailForVerification()), (string) $request->input('hash'))) {
            return response()->json(['message' => 'Invalid verification link.'], 403);
        }
        if (! $request->user()->hasVerifiedEmail()) {
            $request->user()->markEmailAsVerified();
            event(new Verified($request->user()));
        }
        return response()->json(['message' => 'Email verified.', 'verified' => true]);
    }

    /**
     * POST /api/auth/resend-verification
     * Re-issues the verification notification (Task 7 mail queue).
     */
    public function resend(Request $request): JsonResponse
    {
        if ($request->user()->hasVerifiedEmail()) {
            return response()->json(['message' => 'Already verified.'], 409);
        }
        $request->user()->sendEmailVerificationNotification();
        return response()->json(['message' => 'Verification email queued.']);
    }
}