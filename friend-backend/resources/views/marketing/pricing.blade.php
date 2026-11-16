@extends('marketing.layout')

@section('title', 'Pricing')
@section('description', 'Start free. Pay in birr through Chapa or Telebirr when you want regular sessions. No auto-renew traps.')

@section('content')

    <section class="mx-auto max-w-5xl px-5 pt-16 text-center sm:px-8 sm:pt-24">
        <span class="friend-pill">Placeholder pricing · beta</span>
        <h1 class="mt-6 font-display text-display-md sm:text-display-lg">Pay for the talking, not the app</h1>
        <p class="mx-auto mt-5 max-w-xl text-body-lg text-friend-text-secondary">
            The journal and the community rooms stay free forever. You only pay when
            you want a person's time — and you can stop any month.
        </p>
    </section>

    <section class="mx-auto mt-14 max-w-5xl px-5 sm:px-8">
        <div class="grid gap-6 lg:grid-cols-3">

            <article class="friend-card flex flex-col">
                <h2 class="font-display text-headline-lg">Alone time</h2>
                <p class="mt-1 text-body-md text-friend-text-secondary">For keeping your own company well.</p>
                <p class="mt-6 font-display text-display-sm">Free</p>
                <p class="text-body-sm text-friend-text-muted">always</p>
                <ul class="mt-6 flex-1 space-y-2.5 text-body-md text-friend-text-secondary">
                    <li>Private journal, moods and habits</li>
                    <li>Moderated community rooms</li>
                    <li>One introductory conversation</li>
                </ul>
                <a href="{{ route('download') }}" class="friend-btn friend-btn--ghost mt-8">Start here</a>
            </article>

            <article class="friend-card flex flex-col border-friend-primary">
                <div class="flex items-center justify-between gap-3">
                    <h2 class="font-display text-headline-lg">Every week</h2>
                    <span class="friend-pill">Most chosen</span>
                </div>
                <p class="mt-1 text-body-md text-friend-text-secondary">One steady hour, same time each week.</p>
                <p class="mt-6 font-display text-display-sm">ETB 899</p>
                <p class="text-body-sm text-friend-text-muted">per month</p>
                <ul class="mt-6 flex-1 space-y-2.5 text-body-md text-friend-text-secondary">
                    <li>Four sessions a month, any format</li>
                    <li>Same person each time</li>
                    <li>Messages between sessions</li>
                </ul>
                <a href="{{ route('download') }}" class="friend-btn mt-8">Choose weekly</a>
            </article>

            <article class="friend-card flex flex-col">
                <h2 class="font-display text-headline-lg">Whenever</h2>
                <p class="mt-1 text-body-md text-friend-text-secondary">For seasons that need more than a week's patience.</p>
                <p class="mt-6 font-display text-display-sm">ETB 2,400</p>
                <p class="text-body-sm text-friend-text-muted">per month</p>
                <ul class="mt-6 flex-1 space-y-2.5 text-body-md text-friend-text-secondary">
                    <li>Unlimited sessions, fair-use</li>
                    <li>Priority matching within the hour</li>
                    <li>Two professionals if you need both</li>
                </ul>
                <a href="{{ route('contact') }}" class="friend-btn friend-btn--ghost mt-8">Talk to us</a>
            </article>

        </div>
    </section>

    <section class="mx-auto mt-14 max-w-5xl px-5 sm:px-8">
        <div class="rounded-friend-lg border border-friend-border bg-friend-recessed p-8">
            <h2 class="font-display text-headline-lg">Paying, locally</h2>
            <p class="mt-3 max-w-2xl text-body-md text-friend-text-secondary">
                Pay with <strong class="text-friend-text-primary">Telebirr</strong> or by
                card and bank transfer through <strong class="text-friend-text-primary">Chapa</strong>.
                Prices are in birr, so there is no exchange-rate surprise at the end of
                the month. Cancel in the app in two taps — we will never make you email
                someone to leave.
            </p>
            <p class="mt-5 text-body-sm text-friend-text-muted">
                These figures are placeholders while we test with our first hundred
                members in Addis. Anyone who joins during the beta keeps their price
                for a year.
            </p>
        </div>
    </section>

@endsection
