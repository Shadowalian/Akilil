<?php

namespace App\Filament\Pages;

use App\Services\TwoFactorService;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * Optional admin 2FA setup page (reachable from user menu / URL).
 */
class TwoFactorSetup extends Page implements HasForms
{
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-shield-check';
    protected static ?string $title = 'Two-factor authentication';
    protected static ?string $slug = '2fa-setup';
    protected static bool $shouldRegisterNavigation = false;

    public ?string $secret = null;
    public ?string $qrUrl = null;
    public ?array $data = [];

    protected static string $view = 'filament.pages.two-factor-setup';

    public function mount(TwoFactorService $svc): void
    {
        $user = auth()->user();
        if (! $user) {
            abort(401);
        }
        if (! $user->totp_secret) {
            $user->totp_secret = $svc->generateSecret();
            $user->save();
        }
        $this->secret = $user->totp_secret;
        $this->qrUrl = $svc->otpAuthUrl($user->email, $this->secret, 'Akilil');
        $this->form->fill();
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                TextInput::make('code')
                    ->label('6-digit code from your authenticator')
                    ->numeric()
                    ->length(6)
                    ->required(),
            ])
            ->statePath('data');
    }

    public function getHeading(): string|Htmlable
    {
        return 'Set up two-factor authentication';
    }

    public function getSubheading(): ?string
    {
        $user = auth()->user();

        return $user->totp_enabled
            ? 'Your 2FA is already active. To re-issue codes, click "Regenerate".'
            : 'Scan the QR code with Google Authenticator, then submit a 6-digit code to confirm.';
    }

    public function confirm(TwoFactorService $svc): void
    {
        $user = auth()->user();
        $code = $this->form->getState()['code'] ?? null;
        if (! $code || strlen((string) $code) !== 6) {
            throw ValidationException::withMessages(['data.code' => ['Enter the 6-digit code.']]);
        }
        if (! $svc->verifyCode($user->totp_secret, (string) $code)) {
            throw ValidationException::withMessages(['data.code' => ['Invalid or expired code.']]);
        }

        $codes = $svc->generateRecoveryCodes();
        $user->forceFill([
            'totp_enabled' => true,
            'totp_confirmed_at' => now(),
            'totp_recovery_codes' => array_map(fn ($c) => Hash::make($c), $codes),
        ])->save();

        session()->flash('2fa_recovery_codes', $codes);
        Notification::make()->title('Two-factor authentication enabled')->success()->send();
        $this->redirectRoute('filament.admin.pages.dashboard');
    }

    public function regenerateSecret(TwoFactorService $svc): void
    {
        $user = auth()->user();
        $user->forceFill([
            'totp_secret' => $svc->generateSecret(),
            'totp_enabled' => false,
            'totp_confirmed_at' => null,
            'totp_recovery_codes' => null,
        ])->save();
        $this->secret = $user->totp_secret;
        $this->qrUrl = $svc->otpAuthUrl($user->email, $this->secret, 'Akilil');
        Notification::make()->title('Secret regenerated. Re-scan + confirm.')->warning()->send();
    }
}
