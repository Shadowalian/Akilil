<?php

namespace App\Http\Controllers\Api\Webhook;

use App\Events\SessionStateChanged;
use App\Http\Controllers\Controller;
use App\Models\CallSession;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

/**
 * Jitsi webhook receiver.
 *
 * Public endpoint — auth via provider-signed secret (header).
 * In dev / with the public meet.jit.si server, Jitsi does NOT post webhooks
 * (no recording server there). For production with self-hosted Jitsi,
 * configure the Jicofo / Jibri side to POST here with a shared secret.
 *
 * The framework: we verify an X-Webhook-Secret header against a config value,
 * then match the event to a CallSession by room_name and update accordingly.
 */
class JitsiWebhookController extends Controller
{
    /**
     * POST /api/webhooks/jitsi
     * Body shape (loose — different Jitsi builds use different schemas):
     *   { "event": "recording_ready", "room": "friend-123-abcd12", "url": "https://...",
     *     "duration": 1234, "size_bytes": 56789 }
     */
    public function handle(Request $request): JsonResponse
    {
        $expected = config('jitsi.webhook_secret');
        if ($expected) {
            $provided = $request->header('X-Webhook-Secret');
            abort_unless($provided && hash_equals($expected, (string) $provided), 401, 'Invalid webhook secret.');
        }

        $event   = $request->input('event');
        $room    = $request->input('room');
        abort_unless($event && $room, 422, 'Missing event or room.');

        $session = CallSession::where('room_name', $room)->first();
        if (! $session) {
            Log::warning('Jitsi webhook for unknown room', ['room' => $room, 'event' => $event]);
            return response()->json(['ok' => true]);
        }

        if ($event === 'recording_ready') {
            $session->update([
                'recording_url'             => $request->input('url'),
                'recording_size_bytes'      => $request->input('size_bytes'),
                'recording_duration_seconds' => $request->input('duration'),
                'recording_status'          => 'ready',
            ]);
            event(new SessionStateChanged($session->appointment, $session, 'recording_ready'));
        } elseif ($event === 'recording_failed') {
            $session->update(['recording_status' => 'failed']);
        } elseif ($event === 'session_ended') {
            // Defensive: client might miss /session/end; auto-close here.
            if (! $session->ended_at) {
                $session->update(['ended_at' => now(), 'status' => 'completed']);
                if ($session->appointment && $session->appointment->status === 'in_progress') {
                    $session->appointment->update(['status' => 'completed', 'ended_at' => now()]);
                }
            }
        }

        return response()->json(['ok' => true]);
    }
}