<?php

namespace App\Http\Controllers\Api\Safety;

use App\Http\Controllers\Controller;
use App\Models\CrisisFlag;
use App\Models\User;
use App\Notifications\CrisisEscalationNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Notification;

/**
 * A person asks the Akilil safety team to reach out — from the crisis
 * page, or automatically when a screener answer indicates risk of
 * self-harm. Staff are emailed and the request tops the admin queue.
 *
 * This is not an emergency service: the app always shows emergency
 * numbers alongside it.
 */
class CrisisAlertController extends Controller
{
    /** POST /api/crisis/alerts */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validate([
            'reason'         => ['required', 'in:asked_for_help,screener_self_harm'],
            'phone'          => ['nullable', 'string', 'max:32'],
            'contact_method' => ['nullable', 'in:call,message'],
            'message'        => ['nullable', 'string', 'max:2000'],
        ]);

        // One open request is enough: repeat taps update it instead of
        // flooding the team, but still re-alert so nobody misses it.
        $flag = CrisisFlag::where('user_id', $user->id)
            ->whereIn('kind', ['help_request', 'screener'])
            ->whereIn('status', ['open', 'in_review'])
            ->latest('id')
            ->first();

        $kind = $data['reason'] === 'screener_self_harm' ? 'screener' : 'help_request';
        $attrs = [
            'kind'           => $flag?->kind === 'screener' ? 'screener' : $kind,
            'severity'       => $kind === 'screener' ? 1.0 : 0.9,
            'contact_phone'  => $data['phone'] ?? $flag?->contact_phone ?? $user->phone,
            'contact_method' => $data['contact_method'] ?? $flag?->contact_method ?? 'call',
            'user_message'   => $data['message'] ?? $flag?->user_message,
            'matched_signals' => ['reason' => $data['reason']],
        ];

        if ($flag) {
            $flag->update($attrs);
        } else {
            $flag = CrisisFlag::create([
                ...$attrs,
                'user_id'     => $user->id,
                'source_type' => User::class,
                'source_id'   => $user->id,
                'status'      => 'open',
            ]);
        }

        if (! $user->phone && ! empty($data['phone'])) {
            $user->forceFill(['phone' => $data['phone']])->save();
        }

        $staff = User::whereHas('roles', fn ($q) => $q->whereIn('name', ['admin', 'support']))->get();
        Notification::send($staff, new CrisisEscalationNotification($flag->fresh('user')));

        return response()->json(['alert' => $this->present($flag->fresh())], 201);
    }

    /** GET /api/crisis/alerts/latest — so the app can show "we're on it". */
    public function latest(Request $request): JsonResponse
    {
        $flag = CrisisFlag::where('user_id', $request->user()->id)
            ->whereIn('kind', ['help_request', 'screener'])
            ->latest('id')
            ->first();

        return response()->json(['alert' => $flag ? $this->present($flag) : null]);
    }

    private function present(CrisisFlag $flag): array
    {
        return [
            'id'           => $flag->id,
            'status'       => $flag->status,
            'created_at'   => $flag->created_at?->toIso8601String(),
            'contacted_at' => $flag->contacted_at?->toIso8601String(),
            // The person sees whether someone has picked it up, never staff notes.
            'state'        => match (true) {
                $flag->status === 'handled' => 'resolved',
                $flag->contacted_at !== null, $flag->status === 'in_review' => 'in_progress',
                default => 'waiting',
            },
        ];
    }
}
