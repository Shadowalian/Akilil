@extends('marketing.layout')

@section('title', 'Privacy')
@section('description', 'Plain-language privacy notice: what Akilil stores, what it never does, and how to delete everything.')

@section('content')

    <section class="mx-auto max-w-3xl px-5 pt-16 sm:px-8 sm:pt-24">
        <span class="friend-pill">Draft · last updated 12 August 2026</span>
        <h1 class="mt-6 font-display text-display-md sm:text-display-lg">Privacy</h1>
        <p class="mt-5 text-body-lg text-friend-text-secondary">
            The short version: your journal and your conversations are yours. We do not
            sell them, share them, or train anything on them. The longer version is
            below, in plain language — a lawyer-reviewed edition lands before launch.
        </p>
    </section>

    <section class="mx-auto mt-10 max-w-3xl px-5 sm:px-8">
        <div class="friend-card space-y-9">
            @php
                $sections = [
                    ['What we store', 'Your name, phone number or email, the language you prefer, and what you write in the app: journal entries, moods, habits, messages and bookings. Payment details stay with Chapa and Telebirr — we only keep a record that a payment happened.'],
                    ['Why we store it', 'To match you with the right person, to let you pick up where you left off, and to keep the platform safe. Nothing else. We do not build advertising profiles.'],
                    ['Who can see your writing', 'Your journal: only you. Your session messages: you and the professional you were talking to. Our staff can only open a conversation when you report a safety problem, and only the part you point us at.'],
                    ['What we never do', 'Sell your data. Hand it to advertisers. Use your words to train an AI model. Tell your family, your employer or anyone else that you use Akilil.'],
                    ['Deleting everything', 'Delete your account in the app and your journal, messages and profile go within 30 days. We keep only the minimum payment records the law requires us to keep.'],
                    ['Where the data lives', 'Encrypted in transit and at rest, on servers we control. If we ever move to a different country or provider, we will tell you before it happens, not afterwards.'],
                    ['Children', 'Akilil is for people 18 and over. If we learn an account belongs to someone younger, we close it and delete the data.'],
                    ['Questions or requests', 'Ask us for a copy of your data, a correction, or a deletion through the contact page. We answer within 30 days, usually much sooner.'],
                ];
            @endphp

            @foreach ($sections as $i => [$heading, $body])
                <section>
                    <h2 class="font-display text-headline-md">
                        <span class="text-friend-text-muted">{{ str_pad($i + 1, 2, '0', STR_PAD_LEFT) }}</span>
                        {{ $heading }}
                    </h2>
                    <p class="mt-2 text-body-md text-friend-text-secondary">{{ $body }}</p>
                </section>
            @endforeach
        </div>
    </section>

    <section class="mx-auto mt-8 max-w-3xl px-5 sm:px-8">
        <div class="rounded-friend-lg border border-friend-border bg-friend-recessed p-8">
            <p class="text-body-md text-friend-text-secondary">
                Something here unclear or uncomfortable? That is worth an email —
                <a href="{{ route('contact') }}" class="font-semibold">tell us</a> and we
                will fix the wording or the practice.
            </p>
        </div>
    </section>

@endsection
