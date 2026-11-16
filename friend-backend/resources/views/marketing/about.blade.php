@extends('marketing.layout')

@section('title', 'About')
@section('description', 'A small team in Addis Ababa building the thing we needed ourselves.')

@section('content')

    <section class="mx-auto max-w-3xl px-5 pt-16 sm:px-8 sm:pt-24">
        <span class="friend-pill friend-pill--aqua">Addis Ababa · since 2025</span>
        <h1 class="mt-6 font-display text-display-md sm:text-display-lg">
            We named it Akilil on purpose
        </h1>
        <p class="mt-6 text-body-lg text-friend-text-secondary">
            Every other name we tried sounded like a clinic or a startup imported
            from somewhere else. Nobody here says “I need a wellness platform.”
            They say: I wish I had someone to talk to. Akilil is the name we chose
            for care that feels local — mind, language, and presence in one place.
        </p>
    </section>

    <section class="mx-auto mt-12 max-w-3xl px-5 sm:px-8">
        <div class="friend-card">
            <h2 class="font-display text-headline-lg">Where this came from</h2>
            <p class="mt-3 text-body-md text-friend-text-secondary">
                Here, the hard conversation usually happens over buna, with someone who
                has known you for twenty years. That is a good system — until you move
                cities, or the thing you need to say is exactly the thing you cannot
                say to family.
            </p>
            <p class="mt-3 text-body-md text-friend-text-secondary">
                Meanwhile there are trained counsellors in this country whose calendars
                have gaps, and people who would never walk into an office but would
                happily talk on the phone at 9pm. Akilil is a very simple bridge
                between the two.
            </p>
        </div>
    </section>

    <section class="mx-auto mt-8 max-w-3xl px-5 sm:px-8">
        <div class="grid gap-6 sm:grid-cols-3">
            @php
                $beliefs = [
                    ['Language matters', 'Comfort comes in Amharic, Afaan Oromo, Tigrinya — not in translation. Match first on language, always.'],
                    ['Small beats viral', 'A hundred people who feel genuinely held is a better year than a million downloads.'],
                    ['Say the limits out loud', 'We tell you what we cannot do before you need us to do it.'],
                ];
            @endphp
            @foreach ($beliefs as [$title, $body])
                <article class="rounded-friend border border-friend-border bg-friend-surface p-6">
                    <h3 class="font-display text-headline-sm">{{ $title }}</h3>
                    <p class="mt-2 text-body-md text-friend-text-secondary">{{ $body }}</p>
                </article>
            @endforeach
        </div>
    </section>

    <section class="mx-auto mt-12 max-w-3xl px-5 sm:px-8">
        <div class="rounded-friend-lg border border-friend-border bg-friend-recessed p-8">
            <h2 class="font-display text-headline-lg">Who's building it</h2>
            <p class="mt-3 text-body-md text-friend-text-secondary">
                A team of six: two engineers, a designer, a clinical adviser, a
                community lead, and one person who answers every email that lands in
                the inbox. We are hiring listeners and counsellors first, and everyone
                else later.
            </p>
            <div class="mt-7 flex flex-wrap gap-3">
                <a href="{{ route('for-professionals') }}" class="friend-btn">Work with us</a>
                <a href="{{ route('contact') }}" class="friend-btn friend-btn--ghost">Say hello</a>
            </div>
        </div>
    </section>

@endsection
