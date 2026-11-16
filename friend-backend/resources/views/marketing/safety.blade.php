@extends('marketing.layout')

@section('title', 'Safety')
@section('description', 'Akilil is not an emergency service. Here is what we do, what we will not do, and where to call if you need help right now.')

@section('content')

    <section class="mx-auto max-w-3xl px-5 pt-16 sm:px-8 sm:pt-24">
        <span class="friend-pill friend-pill--accent">Please read this one</span>
        <h1 class="mt-6 font-display text-display-md sm:text-display-lg">Safety</h1>
        <p class="mt-5 text-body-lg text-friend-text-secondary">
            We would rather be honest about our limits than clever about our features.
        </p>
    </section>

    {{-- The important box ----------------------------------------- --}}
    <section class="mx-auto mt-10 max-w-3xl px-5 sm:px-8">
        <div class="rounded-friend-lg border-2 border-friend-accent bg-friend-surface p-8">
            <h2 class="font-display text-headline-lg">Akilil is not an emergency service</h2>
            <p class="mt-3 text-body-lg text-friend-text-secondary">
                If you or someone near you is in immediate danger, do not wait for a
                match on Akilil. Contact local emergency services or a crisis line
                straight away. Our professionals are not on call around the clock and
                cannot intervene in a crisis.
            </p>
        </div>
    </section>

    {{-- Hotlines --------------------------------------------------- --}}
    <section class="mx-auto mt-8 max-w-3xl px-5 sm:px-8">
        <div class="friend-card">
            <h2 class="font-display text-headline-md">If you need help right now</h2>
            <p class="mt-2 text-body-sm text-friend-text-muted">
                Placeholder list — being verified with local partners before launch.
                Do not rely on these numbers yet.
            </p>

            <dl class="mt-6 divide-y divide-friend-divider">
                @php
                    $lines = [
                        ['Emergency services (Ethiopia)', '939 / 907 — to be confirmed'],
                        ['Addis Ababa crisis support line', 'number pending partner agreement'],
                        ['Ministry of Health mental health desk', 'number pending'],
                        ['Nearest hospital emergency department', 'find the closest to you before you need it'],
                    ];
                @endphp
                @foreach ($lines as [$label, $value])
                    <div class="flex flex-col gap-1 py-3.5 sm:flex-row sm:items-baseline sm:justify-between sm:gap-6">
                        <dt class="text-body-md font-medium text-friend-text-primary">{{ $label }}</dt>
                        <dd class="text-body-md text-friend-text-secondary">{{ $value }}</dd>
                    </div>
                @endforeach
            </dl>
        </div>
    </section>

    {{-- Do / don't ------------------------------------------------- --}}
    <section class="mx-auto mt-8 max-w-3xl px-5 sm:px-8">
        <div class="grid gap-6 sm:grid-cols-2">
            <div class="friend-card">
                <h2 class="font-display text-headline-md">What we do</h2>
                <ul class="mt-3 space-y-2.5 text-body-md text-friend-text-secondary">
                    <li>Check identity, licence and references before anyone takes a session.</li>
                    <li>Encrypt your messages, journal and call metadata.</li>
                    <li>Put a report button in every conversation, and read every report.</li>
                    <li>Moderate community rooms by real people, not keyword filters alone.</li>
                    <li>Remove professionals who cross a line, permanently.</li>
                </ul>
            </div>

            <div class="friend-card">
                <h2 class="font-display text-headline-md">What we don't do</h2>
                <ul class="mt-3 space-y-2.5 text-body-md text-friend-text-secondary">
                    <li>Diagnose conditions or prescribe medication.</li>
                    <li>Replace hospital, inpatient or psychiatric care.</li>
                    <li>Monitor your account for crises in the background.</li>
                    <li>Sell, share or train models on anything you write.</li>
                    <li>Let anyone contact you outside the app without your say.</li>
                </ul>
            </div>
        </div>
    </section>

    <section class="mx-auto mt-8 max-w-3xl px-5 sm:px-8">
        <div class="rounded-friend-lg border border-friend-border bg-friend-recessed p-8">
            <h2 class="font-display text-headline-md">Something went wrong in a session?</h2>
            <p class="mt-2.5 text-body-md text-friend-text-secondary">
                Tell us. A person reads every safety report, usually the same day, and
                we will tell you what we did about it.
            </p>
            <a href="{{ route('contact') }}" class="friend-btn mt-7">Report a concern</a>
        </div>
    </section>

@endsection
