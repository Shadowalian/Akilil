<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Device\StoreDeviceRequest;
use App\Models\Device;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    /**
     * POST /api/device-tokens
     * Flutter apps register their FCM/APNs token on login + on token rotation.
     * Task 10 wires the actual push fan-out via Notification::send().
     */
    public function store(StoreDeviceRequest $request): JsonResponse
    {
        $user = $request->user();
        $payload = $request->validated();

        $device = Device::updateOrCreate(
            ['user_id' => $user->id, 'push_token' => $payload['push_token']],
            array_merge($payload, ['user_id' => $user->id, 'is_active' => true, 'last_seen_at' => now()])
        );

        return response()->json([
            'id'           => $device->id,
            'platform'     => $device->platform,
            'is_active'    => $device->is_active,
            'registered_at'=> $device->created_at?->toIso8601String(),
        ], 201);
    }

    /**
     * DELETE /api/device-tokens/{id}
     * Called on logout or when the OS revokes the push registration.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $device = Device::where('id', $id)->where('user_id', $request->user()->id)->firstOrFail();
        $device->delete();
        return response()->json(['ok' => true]);
    }

    /**
     * POST /api/device-tokens/{id}/deactivate
     * Soft-disable (used when FCM returns INVALID_REGISTRATION).
     */
    public function deactivate(Request $request, int $id): JsonResponse
    {
        $device = Device::where('id', $id)->where('user_id', $request->user()->id)->firstOrFail();
        $device->update(['is_active' => false]);
        return response()->json(['ok' => true]);
    }
}