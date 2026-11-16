{{-- =====================================================================
     Akilil — public marketing layout (Task 12)

     Nav + footer shell for every page under resources/views/marketing.
     Fonts (Fraunces / Inter) and the full token set arrive through
     resources/css/app.css, which imports friend-tokens.css — so one
     @vite call is all this needs.

     No JS framework: the mobile menu is a native <details> disclosure.
     ===================================================================== --}}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'A friend when you need a human') — Akilil</title>
    <meta name="description" content="@yield('description', 'Akilil connects you with warm, verified people to talk to — in Amharic, Afaan Oromo, Tigrinya or English.')">
    @vite(['resources/css/app.css'])
</head>
<body class="relative min-h-screen flex flex-col overflow-x-hidden">

@php
    $nav = [
        'how-it-works' => 'How it works',
        'for-professionals' => 'For professionals',
        'pricing' => 'Pricing',
        'safety' => 'Safety',
        'about' => 'About',
        'contact' => 'Contact',
    ];
@endphp

{{-- Candy wash behind the top of every page. --}}
<div aria-hidden="true" class="pointer-events-none absolute inset-x-0 top-0 -z-10 h-[460px]">
    <div class="absolute -left-24 -top-28 h-80 w-80 rounded-full bg-friend-primary-soft opacity-70 blur-3xl"></div>
    <div class="absolute right-0 -top-20 h-72 w-72 rounded-full bg-friend-aqua-soft opacity-80 blur-3xl"></div>
    <div class="absolute left-1/3 top-24 h-56 w-56 rounded-full bg-friend-accent opacity-10 blur-3xl"></div>
</div>

<a href="#main"
   class="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-50 focus:rounded-friend-pill focus:bg-friend-primary focus:px-5 focus:py-3 focus:text-body-md focus:font-semibold focus:text-friend-on-primary">
    Skip to content
</a>

<header class="sticky top-0 z-40 border-b border-friend-border bg-friend-bg">
    <div class="mx-auto flex max-w-6xl items-center justify-between gap-4 px-5 py-4 sm:px-8">
        <a href="{{ route('home') }}" class="flex items-center gap-2.5 text-friend-text-primary hover:text-friend-text-primary">
            <span class="flex h-9 w-9 items-center justify-center rounded-friend-pill bg-friend-primary text-friend-on-primary" aria-hidden="true">
                <span class="text-headline-sm">✦</span>
            </span>
            <span class="font-display text-headline-md">Akilil</span>
        </a>

        {{-- Desktop nav --}}
        <nav class="hidden items-center gap-6 lg:flex" aria-label="Main">
            @foreach ($nav as $route => $label)
                <a href="{{ route($route) }}"
                   @class([
                       'text-body-md transition-colors',
                       'font-semibold text-friend-primary-deep' => request()->routeIs($route),
                       'text-friend-text-secondary hover:text-friend-primary-deep' => ! request()->routeIs($route),
                   ])>{{ $label }}</a>
            @endforeach
            <a href="{{ route('download') }}" class="friend-btn friend-btn--accent">Get the app</a>
        </nav>

        {{-- Mobile: native disclosure, stacked links, zero JS --}}
        <details class="lg:hidden">
            <summary class="friend-btn friend-btn--ghost cursor-pointer list-none [&::-webkit-details-marker]:hidden">
                Menu
            </summary>
            <div class="absolute inset-x-0 top-full border-b border-friend-border bg-friend-surface px-5 py-4 shadow-friend-pop">
                <nav class="flex flex-col" aria-label="Mobile">
                    @foreach ($nav as $route => $label)
                        <a href="{{ route($route) }}"
                           class="border-b border-friend-divider py-3 text-body-lg {{ request()->routeIs($route) ? 'font-semibold text-friend-primary-deep' : 'text-friend-text-primary' }}">
                            {{ $label }}
                        </a>
                    @endforeach
                    <a href="{{ route('download') }}" class="friend-btn friend-btn--accent mt-4">Get the app</a>
                </nav>
            </div>
        </details>
    </div>
</header>

<main id="main" class="flex-1">
    @if (session('status'))
        <div class="mx-auto max-w-6xl px-5 pt-6 sm:px-8">
            <div class="friend-card flex items-start gap-3 border-friend-primary-soft bg-friend-recessed" role="status">
                <span aria-hidden="true" class="text-headline-md leading-none text-friend-primary-deep">✓</span>
                <p class="text-body-md text-friend-text-primary">{{ session('status') }}</p>
            </div>
        </div>
    @endif

    @yield('content')
</main>

<footer class="mt-24 border-t border-friend-border bg-friend-surface">
    <div class="mx-auto max-w-6xl px-5 py-14 sm:px-8">
        <div class="grid gap-10 sm:grid-cols-2 lg:grid-cols-4">
            <div>
                <p class="font-display text-headline-md">Akilil</p>
                <p class="mt-3 max-w-xs text-body-md text-friend-text-secondary">
                    Built in Addis Ababa for anyone who has ever typed a long message
                    and then deleted it.
                </p>
            </div>

            <div>
                <p class="text-body-sm font-semibold uppercase tracking-wide text-friend-text-muted">Product</p>
                <ul class="mt-3 space-y-2 text-body-md">
                    <li><a href="{{ route('how-it-works') }}" class="text-friend-text-secondary hover:text-friend-primary-deep">How it works</a></li>
                    <li><a href="{{ route('pricing') }}" class="text-friend-text-secondary hover:text-friend-primary-deep">Pricing</a></li>
                    <li><a href="{{ route('download') }}" class="text-friend-text-secondary hover:text-friend-primary-deep">Download</a></li>
                    <li><a href="{{ route('for-professionals') }}" class="text-friend-text-secondary hover:text-friend-primary-deep">For professionals</a></li>
                </ul>
            </div>

            <div>
                <p class="text-body-sm font-semibold uppercase tracking-wide text-friend-text-muted">Company</p>
                <ul class="mt-3 space-y-2 text-body-md">
                    <li><a href="{{ route('about') }}" class="text-friend-text-secondary hover:text-friend-primary-deep">About</a></li>
                    <li><a href="{{ route('safety') }}" class="text-friend-text-secondary hover:text-friend-primary-deep">Safety</a></li>
                    <li><a href="{{ route('contact') }}" class="text-friend-text-secondary hover:text-friend-primary-deep">Contact</a></li>
                </ul>
            </div>

            <div>
                <p class="text-body-sm font-semibold uppercase tracking-wide text-friend-text-muted">Legal</p>
                <ul class="mt-3 space-y-2 text-body-md">
                    <li><a href="{{ route('privacy') }}" class="text-friend-text-secondary hover:text-friend-primary-deep">Privacy</a></li>
                    <li><a href="{{ route('terms') }}" class="text-friend-text-secondary hover:text-friend-primary-deep">Terms</a></li>
                </ul>
            </div>
        </div>

        <div class="mt-12 rounded-friend border border-friend-border bg-friend-bg p-5">
            <p class="text-body-md text-friend-text-secondary">
                <strong class="text-friend-text-primary">Akilil is not an emergency service.</strong>
                If someone is in immediate danger, please contact local emergency
                services or a crisis line — see our
                <a href="{{ route('safety') }}" class="font-semibold">safety page</a>.
            </p>
        </div>

        <p class="mt-8 text-body-sm text-friend-text-muted">
            © {{ date('Y') }} Akilil. Addis Ababa, Ethiopia.
        </p>
    </div>
</footer>

</body>
</html>
