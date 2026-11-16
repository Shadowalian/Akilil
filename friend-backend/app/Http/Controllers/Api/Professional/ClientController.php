<?php

namespace App\Http\Controllers\Api\Professional;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ClientController extends Controller
{
    /**
     * GET /api/professional/clients
     * The distinct people this professional has ever had a session with,
     * with their session count and most recent session.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403, 'Only professionals can view this.');

        $rows = Appointment::query()
            ->where('professional_user_id', $user->id)
            ->selectRaw('user_id, COUNT(*) as session_count, MAX(scheduled_at) as last_session_at')
            ->groupBy('user_id')
            ->orderByDesc('last_session_at')
            ->get();

        $clients = User::whereIn('id', $rows->pluck('user_id'))->get()->keyBy('id');

        $data = $rows->map(function ($row) use ($clients) {
            $client = $clients->get($row->user_id);
            if (! $client) {
                return null;
            }
            return [
                'user' => [
                    'id'          => $client->id,
                    'name'        => $client->name,
                    'avatar_path' => $client->avatar_path,
                ],
                'session_count'   => (int) $row->session_count,
                'last_session_at' => $row->last_session_at
                    ? CarbonImmutable::parse($row->last_session_at)->toIso8601String()
                    : null,
            ];
        })->filter()->values();

        return response()->json(['data' => $data]);
    }
}
