<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Auth\ForgotPasswordRequest;
use App\Http\Requests\Api\Auth\ResetPasswordRequest;
use App\Models\User;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class PasswordController extends Controller
{
    /**
     * POST /api/auth/forgot-password
     */
    public function sendLink(ForgotPasswordRequest $request): JsonResponse
    {
        // Always 200 even if the user doesn't exist — don't leak.
        Password::sendResetLink($request->only('email'));
        return response()->json(['message' => 'If the email exists, a reset link has been sent.']);
    }

    /**
     * POST /api/auth/reset-password
     */
    public function reset(ResetPasswordRequest $request): JsonResponse
    {
        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function (User $user, string $password) {
                $user->forceFill([
                    'password'       => Hash::make($password),
                    'remember_token' => Str::random(60),
                ])->save();
                event(new PasswordReset($user));
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            throw ValidationException::withMessages(['token' => ['Invalid or expired reset token.']]);
        }
        return response()->json(['message' => 'Password reset.']);
    }
}
