@extends('marketing.layout')

@section('title', 'Download')
@section('description', 'Akilil is coming to Google Play and the App Store. Ask for a beta invite in the meantime.')

@section('content')

    <section class="mx-auto max-w-3xl px-5 pt-16 sm:px-8 sm:pt-24">
        <span class="friend-pill friend-pill--accent">Almost out the door</span>
        <h1 class="mt-6 font-display text-display-md sm:text-display-lg">Get the app</h1>
        <p class="mt-5 text-body-lg text-friend-text-secondary">
            We are in the last round of private testing in Addis. Rather than ship
            something half-warm, we would rather you wait a few weeks.
        </p>
    </section>

    <section class="mx-auto mt-10 max-w-3xl px-5 sm:px-8">
        <div class="grid gap-6 sm:grid-cols-2">
            <div class="friend-card flex flex-col items-start">
                <span class="friend-pill">Coming soon</span>
                <h2 class="mt-5 font-display text-headline-md">Google Play</h2>
                <p class="mt-2 flex-1 text-body-md text-friend-text-secondary">
                    Android 8 and up. Built small on purpose — under 20 MB, and it works
                    on a patchy connection.
                </p>
                <span class="friend-btn mt-6 cursor-not-allowed opacity-60" aria-disabled="true">Play Store — soon</span>
            </div>

            <div class="friend-card flex flex-col items-start">
                <span class="friend-pill">Coming soon</span>
                <h2 class="mt-5 font-display text-headline-md">App Store</h2>
                <p class="mt-2 flex-1 text-body-md text-friend-text-secondary">
                    iOS 15 and up. In review right behind the Android build.
                </p>
                <span class="friend-btn mt-6 cursor-not-allowed opacity-60" aria-disabled="true">App Store — soon</span>
            </div>
        </div>
    </section>

    <section class="mx-auto mt-8 max-w-3xl px-5 sm:px-8">
        <div class="rounded-friend-lg border border-friend-border bg-friend-recessed p-8">
            <h2 class="font-display text-headline-lg">Want in early?</h2>
            <p class="mt-2.5 max-w-xl text-body-md text-friend-text-secondary">
                We hand out a small number of beta invites every week. Send us a note
                and tell us roughly what you are hoping for — that is the only
                qualification.
            </p>
            <a href="{{ route('contact') }}" class="friend-btn friend-btn--accent mt-7">Ask for an invite</a>
        </div>
    </section>

    <section class="mx-auto mt-8 max-w-3xl px-5 sm:px-8">
        <div class="friend-card">
            <h2 class="font-display text-headline-md">What's there on day one</h2>
            <ul class="mt-3 space-y-2.5 text-body-md text-friend-text-secondary">
                <li>Matching with a listener or professional, in your language</li>
                <li>Chat, voice and video sessions you can switch between</li>
                <li>Your private journal, moods and habits</li>
                <li>Moderated community rooms</li>
                <li>Telebirr and Chapa payments, in birr</li>
            </ul>
        </div>
    </section>

@endsection
