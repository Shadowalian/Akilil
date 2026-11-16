<x-filament-panels::page>
    <div class="space-y-6 max-w-3xl">
        <x-filament::section>
            <x-slot name="heading">Step 1 — Scan QR</x-slot>
            <x-slot name="description">
                Open Google Authenticator (or 1Password / Authy) and scan the QR code below,
                or enter the secret manually.
            </x-slot>

            <div class="grid gap-6 sm:grid-cols-2 items-start">
                <div class="space-y-3">
                    <p class="text-sm text-gray-500 dark:text-gray-400">Manual secret</p>
                    <p class="font-mono text-sm break-all bg-gray-50 dark:bg-white/5 p-3 rounded-xl border border-gray-200 dark:border-white/10">
                        {{ $secret }}
                    </p>
                </div>
                <div class="flex items-center justify-center rounded-xl bg-white p-4 border border-gray-200 dark:border-white/10">
                    <img
                        src="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data={{ urlencode($qrUrl) }}"
                        alt="2FA QR code"
                        width="200"
                        height="200"
                        class="rounded"
                    />
                </div>
            </div>
        </x-filament::section>

        <x-filament::section>
            <x-slot name="heading">Step 2 — Confirm with a code</x-slot>
            <x-slot name="description">
                Enter the current 6-digit code from your authenticator to confirm the setup.
            </x-slot>

            <form wire:submit.prevent="confirm" class="space-y-4 max-w-sm">
                {{ $this->form }}
                <div class="flex flex-wrap gap-3">
                    <x-filament::button type="submit" color="primary">
                        Enable 2FA
                    </x-filament::button>
                    <x-filament::button
                        color="gray"
                        type="button"
                        wire:click="regenerateSecret"
                        wire:confirm="Regenerating will invalidate the current QR. Continue?">
                        Regenerate secret
                    </x-filament::button>
                </div>
            </form>

            @if (session('2fa_recovery_codes'))
                <div class="mt-6 p-4 rounded-xl border border-amber-300 bg-amber-50 dark:bg-amber-500/10 dark:border-amber-400/30">
                    <p class="font-semibold text-amber-800 dark:text-amber-200 mb-2">Save these recovery codes — they are shown only once.</p>
                    <ul class="grid grid-cols-2 gap-1 font-mono text-sm">
                        @foreach (session('2fa_recovery_codes') as $code)
                            <li>{{ $code }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif
        </x-filament::section>
    </div>
</x-filament-panels::page>
