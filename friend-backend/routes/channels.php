<?php

use App\Models\CommunityChannel;
use App\Models\Conversation;
use Illuminate\Support\Facades\Broadcast;

/*
 * Akilil Platform — channel authorization for Reverb.
 *
 * Every channel defined here gates who can subscribe. The Flutter apps
 * call /broadcasting/auth (Sanctum) with their Bearer token; Reverb
 * forwards to these closures; the closure returns true/false.
 *
 * Patterns:
 *   - private-conversation.{id}  →  only conversation participants
 *   - private-appointments.{id}  →  the user themselves only
 *   - private-channel.{id}       →  community channel members
 *   - presence-channel.{id}      →  same as private-channel.* but with presence
 *   - presence-notifications.*   →  opt-in global presence
 */

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

Broadcast::channel('conversation.{conversationId}', function ($user, $conversationId) {
    return Conversation::where('id', $conversationId)
        ->whereHas('participants', fn ($q) => $q->where('user_id', $user->id))
        ->exists();
});

Broadcast::channel('appointments.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});

Broadcast::channel('channel.{channelId}', function ($user, $channelId) {
    $ch = CommunityChannel::find($channelId);
    if (! $ch) return false;
    if (! $ch->is_private) return true;     // public channels: anyone
    return $ch->memberUsers()->where('users.id', $user->id)->exists();
});

// presence-channel.* is the same auth as channel.* but with presence join events
Broadcast::channel('presence-channel.{channelId}', function ($user, $channelId) {
    return Broadcast::channel('channel.' . $channelId, $user, $channelId);
});