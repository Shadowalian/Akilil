<?php

namespace App\Services;

use App\Models\Appointment;
use App\Models\AvailabilityBlock;
use App\Models\User;
use Carbon\CarbonImmutable;

/**
 * SlotService — turns a professional's recurring rules + one-off blocks
 * + existing bookings into the concrete list of bookable slot starts.
 *
 * Timezone model:
 *   - Each rule has its own timezone (rule.timezone); wall times are on the
 *     calendar date the client selected, interpreted in that rule timezone.
 *   - appointments.scheduled_at is UTC at rest
 *   - start_local is returned in the requesting user's timezone
 */
class SlotService
{
    /**
     * @return array<int, array{start_at:string, start_local:string, duration_minutes:int, timezone:string}>
     */
    public function forDay(User $professional, CarbonImmutable $dayInUserTz, string $userTimezone, ?int $durationOverride = null): array
    {
        // Weekday of the calendar day the client picked (1=Mon … 7=Sun).
        $weekday = (int) $dayInUserTz->isoFormat('E');
        $dateStr = $dayInUserTz->toDateString();

        $rules = $professional->availabilitySlotRules()
            ->where('weekday', $weekday)
            ->where('is_active', true)
            ->where(function ($q) use ($dateStr) {
                $q->whereNull('effective_from')->orWhereDate('effective_from', '<=', $dateStr);
            })
            ->where(function ($q) use ($dateStr) {
                $q->whereNull('effective_until')->orWhereDate('effective_until', '>=', $dateStr);
            })
            ->get();

        if ($rules->isEmpty()) {
            return [];
        }

        $candidates = [];
        foreach ($rules as $rule) {
            $duration = $durationOverride ?: ($rule->slot_duration_minutes ?: 45);
            $buffer   = $rule->buffer_minutes ?: 0;
            $step     = max(1, $duration + $buffer);
            $ruleTz   = $rule->timezone ?: 'UTC';

            $startHm = substr((string) $rule->start_time, 0, 5);
            $endHm   = substr((string) $rule->end_time, 0, 5);

            try {
                $cursor = CarbonImmutable::createFromFormat('Y-m-d H:i', "$dateStr $startHm", $ruleTz);
                $end    = CarbonImmutable::createFromFormat('Y-m-d H:i', "$dateStr $endHm", $ruleTz);
            } catch (\Throwable) {
                continue;
            }

            if ($end->lte($cursor)) {
                continue;
            }

            // Walk [start, end] generating slots that fully fit.
            $slotStart = $cursor;
            while ($slotStart->addMinutes($duration)->lte($end)) {
                $slotStartUtc = $slotStart->setTimezone('UTC');
                $slotEndUtc   = $slotStartUtc->addMinutes($duration);

                $candidates[] = [
                    'utc_start' => $slotStartUtc,
                    'utc_end'   => $slotEndUtc,
                    'duration'  => $duration,
                ];
                $slotStart = $slotStart->addMinutes($step);
            }
        }

        // Subtract one-off blocks overlapping the selected calendar day (in user TZ).
        $dayStartUtc = $dayInUserTz->startOfDay()->setTimezone('UTC');
        $dayEndUtc   = $dayInUserTz->endOfDay()->setTimezone('UTC');
        $blocks = AvailabilityBlock::where('user_id', $professional->id)
            ->where('start_at', '<', $dayEndUtc)
            ->where('end_at',   '>', $dayStartUtc)
            ->get(['start_at', 'end_at']);
        $candidates = array_values(array_filter($candidates, function ($c) use ($blocks) {
            foreach ($blocks as $b) {
                if ($c['utc_start']->lt($b->end_at) && $c['utc_end']->gt($b->start_at)) {
                    return false;
                }
            }
            return true;
        }));

        $existing = Appointment::where('professional_user_id', $professional->id)
            ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
            ->where('scheduled_at', '<', $dayEndUtc)
            ->whereRaw($this->appointmentEndSql().' > ?', [$dayStartUtc->toDateTimeString()])
            ->get(['scheduled_at', 'duration_minutes']);
        $candidates = array_values(array_filter($candidates, function ($c) use ($existing) {
            foreach ($existing as $a) {
                $aStart = CarbonImmutable::parse($a->scheduled_at)->utc();
                $aEnd   = $aStart->addMinutes((int) $a->duration_minutes);
                if ($c['utc_start']->lt($aEnd) && $c['utc_end']->gt($aStart)) {
                    return false;
                }
            }
            return true;
        }));

        $now = CarbonImmutable::now('UTC');
        $candidates = array_values(array_filter($candidates, fn ($c) => $c['utc_start']->gt($now)));

        // Deduplicate identical starts (stacked duplicate rules).
        $seen = [];
        $unique = [];
        foreach ($candidates as $c) {
            $key = $c['utc_start']->toIso8601String().'|'.$c['duration'];
            if (isset($seen[$key])) {
                continue;
            }
            $seen[$key] = true;
            $unique[] = $c;
        }

        $userTz = $userTimezone ?: 'UTC';
        return array_map(function ($c) use ($userTz) {
            $local = $c['utc_start']->setTimezone($userTz);
            return [
                'start_at'         => $c['utc_start']->toIso8601String(),
                'start_local'      => $local->toIso8601String(),
                'timezone'         => $userTz,
                'duration_minutes' => $c['duration'],
            ];
        }, $unique);
    }

    public function isSlotBookable(User $professional, CarbonImmutable $startUtc, int $durationMinutes): bool
    {
        $endUtc = $startUtc->addMinutes($durationMinutes);

        $rules = $professional->availabilitySlotRules()
            ->where('is_active', true)
            ->get();
        if ($rules->isEmpty()) {
            return false;
        }

        $timeOk = false;
        foreach ($rules as $rule) {
            $ruleTz = $rule->timezone ?: 'UTC';
            $startInRule = $startUtc->setTimezone($ruleTz);
            $weekday = (int) $startInRule->isoFormat('E');
            if ((int) $rule->weekday !== $weekday) {
                continue;
            }

            $dateStr = $startInRule->toDateString();
            $startHm = substr((string) $rule->start_time, 0, 5);
            $endHm   = substr((string) $rule->end_time, 0, 5);

            try {
                $ruleStart = CarbonImmutable::createFromFormat('Y-m-d H:i', "$dateStr $startHm", $ruleTz);
                $ruleEnd   = CarbonImmutable::createFromFormat('Y-m-d H:i', "$dateStr $endHm", $ruleTz);
            } catch (\Throwable) {
                continue;
            }

            $slotEnd = $startInRule->addMinutes($durationMinutes);
            if ($startInRule->gte($ruleStart) && $slotEnd->lte($ruleEnd)) {
                $timeOk = true;
                break;
            }
        }
        if (! $timeOk) {
            return false;
        }

        $overlappingBlock = AvailabilityBlock::where('user_id', $professional->id)
            ->where('start_at', '<', $endUtc)
            ->where('end_at',   '>', $startUtc)
            ->exists();
        if ($overlappingBlock) {
            return false;
        }

        $endExpr = $this->appointmentEndSql();
        $overlappingAppt = Appointment::where('professional_user_id', $professional->id)
            ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
            ->where('scheduled_at', '<', $endUtc)
            ->whereRaw("$endExpr > ?", [$startUtc->toDateTimeString()])
            ->exists();

        return ! $overlappingAppt;
    }

    private function appointmentEndSql(): string
    {
        $driver = Appointment::query()->getConnection()->getDriverName();
        return $driver === 'sqlite'
            ? "datetime(scheduled_at, '+' || duration_minutes || ' minutes')"
            : 'DATE_ADD(scheduled_at, INTERVAL duration_minutes MINUTE)';
    }
}
