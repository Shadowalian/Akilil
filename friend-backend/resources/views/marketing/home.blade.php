@extends('marketing.layout')

@section('title', 'A friend when you need a human')
@section('description', 'Talk to a warm, verified person — by chat, voice or video. In Amharic, Afaan Oromo, Tigrinya or English. Akilil is built in Addis Ababa.')

@section('content')

    {{-- Hero ------------------------------------------------------- --}}
    <section class="mx-auto max-w-6xl px-5 pb-16 pt-16 sm:px-8 sm:pt-24">
        <span class="friend-pill friend-pill--accent">Private beta · Addis Ababa</span>

        <h1 class="mt-6 max-w-3xl font-display text-display-md sm:text-display-lg lg:text-[3.25rem] lg:leading-[1.08]">
            A friend when you need a human
        </h1>

        <p class="mt-6 max-w-xl text-body-lg text-friend-text-secondary">
            Not a chatbot. Not a lecture. A real person who has time for you today —
            by message, voice or video, in the language you dream in.
        </p>

        <div class="mt-9 flex flex-wrap items-center gap-3">
            <a href="{{ route('download') }}" class="friend-btn">Download the app</a>
            <a href="{{ route('for-professionals') }}" class="friend-btn friend-btn--ghost">For professionals</a>
        </div>

        <p class="mt-5 text-body-sm text-friend-text-muted">
            Free to start · No card needed · Chapa &amp; Telebirr when you're ready
        </p>
    </section>

    {{-- Three things it does -------------------------------------- --}}
    <section class="mx-auto max-w-6xl px-5 sm:px-8">
        <div class="grid gap-6 md:grid-cols-3">

            <article class="friend-card">
                <span class="flex h-12 w-12 items-center justify-center rounded-friend-pill bg-friend-primary-soft" aria-hidden="true">
                    <span class="text-headline-md">✦</span>
                </span>
                <h2 class="mt-5 font-display text-headline-lg">Someone listens</h2>
                <p class="mt-2.5 text-body-md text-friend-text-secondary">
                    Say the messy version. No tidying up first. Verified listeners and
                    licensed professionals, matched to what you're carrying — usually
                    within the hour.
                </p>
            </article>

            <article class="friend-card">
                <span class="flex h-12 w-12 items-center justify-center rounded-friend-pill bg-friend-aqua-soft" aria-hidden="true">
                    <span class="text-headline-md">◍</span>
                </span>
                <h2 class="mt-5 font-display text-headline-lg">A private journal</h2>
                <p class="mt-2.5 text-body-md text-friend-text-secondary">
                    Moods, habits, a sentence before bed. Yours alone — nothing is shared
                    with anyone unless you hand it over yourself.
                </p>
            </article>

            <article class="friend-card">
                <span class="flex h-12 w-12 items-center justify-center rounded-friend-pill bg-friend-primary-soft" aria-hidden="true">
                    <span class="text-headline-md">◇</span>
                </span>
                <h2 class="mt-5 font-display text-headline-lg">A quiet community</h2>
                <p class="mt-2.5 text-body-md text-friend-text-secondary">
                    Small, moderated rooms where people say the thing they can't say at
                    home. No follower counts. No performing.
                </p>
            </article>

        </div>
    </section>

    {{-- Warmth strip ---------------------------------------------- --}}
    <section class="mx-auto mt-20 max-w-6xl px-5 sm:px-8">
        <div class="rounded-friend-lg border border-friend-border bg-friend-recessed p-8 sm:p-12">
            <p class="max-w-2xl font-display text-headline-lg sm:text-display-sm">
                “I didn't want advice. I wanted someone to sit with me for twenty
                minutes and not check their phone.”
            </p>
            <p class="mt-5 text-body-md text-friend-text-secondary">
                — what we heard, over and over, from the eighty people we spoke to
                before writing a single line of code.
            </p>
            <a href="{{ route('how-it-works') }}" class="friend-btn friend-btn--ghost mt-8">See how it works</a>
        </div>
    </section>

    {{-- Safety note ----------------------------------------------- --}}
    <section class="mx-auto mt-16 max-w-6xl px-5 sm:px-8">
        <div class="friend-card border-friend-aqua-soft">
            <h2 class="font-display text-headline-md">A word about safety</h2>
            <p class="mt-2.5 max-w-2xl text-body-md text-friend-text-secondary">
                Akilil is for the ordinary heavy days — not for emergencies. We don't
                diagnose, we don't prescribe, and we will always tell you plainly when
                something is beyond what we can hold. Every professional is
                identity-checked before they ever meet you.
            </p>
            <a href="{{ route('safety') }}" class="mt-4 inline-block text-body-md font-semibold">
                Read our safety commitments →
            </a>
        </div>
    </section>

@endsection
