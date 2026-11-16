<?php

namespace App\Providers\Filament;

use App\Models\User;
use App\Filament\Pages\TwoFactorSetup;
use Filament\Enums\ThemeMode;
use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Navigation\MenuItem;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Filament\View\PanelsRenderHook;
use Filament\Widgets;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\AuthenticateSession;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\HtmlString;
use Illuminate\View\Middleware\ShareErrorsFromSession;

/**
 * Filament admin panel for Akilil — aqua brand matching the Flutter apps.
 */
class AdminPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->default()
            ->id('admin')
            ->path('admin')
            ->brandName('Akilil Admin')
            ->login()
            ->darkMode(false)
            ->defaultThemeMode(ThemeMode::Light)
            ->font('Urbanist')
            ->colors([
                'primary' => Color::hex('#1A9FC4'),
                'success' => Color::hex('#10B981'),
                'warning' => Color::hex('#FE814B'),
                'info' => Color::hex('#3DB8D0'),
                'danger' => Color::hex('#C0392B'),
                'gray' => Color::hex('#3A4558'),
            ])
            ->renderHook(
                PanelsRenderHook::HEAD_END,
                fn (): HtmlString => new HtmlString(<<<'HTML'
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Urbanist:ital,wght@0,300..900;1,300..900&display=swap" rel="stylesheet">
<style>
  :root {
    --akilil-bg: #F5F9FA;
    --akilil-primary: #1A9FC4;
    --akilil-primary-dark: #1282A2;
    --akilil-accent: #FE814B;
    --akilil-teal: #3ECF8E;
    --akilil-mid: #3DB8D0;
    --font-family: 'Urbanist', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  }
  body, .fi-body, .fi-simple-layout, .fi-main-ctn, .fi-topbar, .fi-sidebar, input, button, select, textarea {
    font-family: 'Urbanist', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
  }
  .fi-body, .fi-simple-layout, .fi-main-ctn {
    background-color: var(--akilil-bg) !important;
  }
  .fi-simple-main {
    background: linear-gradient(160deg, #D6F0F7 0%, #F5F9FA 48%, #E8F4F7 100%) !important;
    border-radius: 20px !important;
    border: 1px solid rgba(26, 159, 196, 0.15) !important;
    box-shadow: 0 12px 36px rgba(26, 159, 196, 0.1) !important;
  }
  .fi-btn-primary, .fi-btn.fi-color-primary {
    --c-400: 26, 159, 196;
    --c-500: 26, 159, 196;
    --c-600: 18, 130, 162;
    border-radius: 12px !important;
    font-weight: 700 !important;
    box-shadow: 0 4px 14px rgba(26, 159, 196, 0.25) !important;
    transition: all 0.2s ease-in-out !important;
  }
  .fi-btn-primary:hover, .fi-btn.fi-color-primary:hover {
    transform: translateY(-1px);
    box-shadow: 0 6px 18px rgba(26, 159, 196, 0.35) !important;
  }
  .fi-section, .fi-card, .fi-ta-ctn {
    border-radius: 16px !important;
    border: 1px solid rgba(26, 159, 196, 0.12) !important;
    box-shadow: 0 2px 12px rgba(20, 40, 60, 0.04) !important;
  }
  .fi-sidebar-item-active .fi-sidebar-item-button {
    background-color: rgba(26, 159, 196, 0.12) !important;
    color: #1A9FC4 !important;
    border-radius: 10px !important;
    font-weight: 700 !important;
  }
  .fi-badge {
    border-radius: 9999px !important;
    font-weight: 600 !important;
  }
  .fi-topbar {
    border-bottom: 1px solid rgba(26, 159, 196, 0.1) !important;
    background: rgba(255, 255, 255, 0.95) !important;
    backdrop-filter: blur(8px) !important;
  }
</style>
HTML),
            )
            ->discoverResources(in: app_path('Filament/Resources'), for: 'App\\Filament\\Resources')
            ->discoverPages(in: app_path('Filament/Pages'), for: 'App\\Filament\\Pages')
            ->pages([
                \App\Filament\Pages\Dashboard::class,
                TwoFactorSetup::class,
            ])
            ->discoverWidgets(in: app_path('Filament/Widgets'), for: 'App\\Filament\\Widgets')
            ->widgets([
                Widgets\AccountWidget::class,
                \App\Filament\Widgets\StatsOverview::class,
                \App\Filament\Widgets\SessionsChart::class,
                \App\Filament\Widgets\RevenueChart::class,
            ])
            ->navigationGroups([
                'Care',
                'People',
                'Finance',
                'Safety',
                'Community',
                'Compliance',
            ])
            ->userMenuItems([
                'logout' => MenuItem::make()->label('Log out')->url(fn () => route('filament.admin.auth.logout')),
            ])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                VerifyCsrfToken::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
            ])
            ->authMiddleware([
                Authenticate::class,
                // Staff must have TOTP on before they can open any admin page.
                \App\Http\Middleware\PanelEnsureTwoFactorEnabled::class,
            ]);
    }

    public static function canAccess(): bool
    {
        /** @var User|null $user */
        $user = Auth::user();
        return $user !== null && $user->hasAnyRole(['admin', 'support', 'moderator']);
    }
}
