@extends('marketing.layout')

@section('title', 'For professionals')
@section('description', 'Counsellors, therapists, coaches and spiritual guides: set your own hours, get verified, and receive payouts in birr.')

@section('content')

    <section class="mx-auto max-w-5xl px-5 pt-16 sm:px-8 sm:pt-24">
        <span class="friend-pill friend-pill--aqua">Now reviewing applications</span>
        <h1 class="mt-6 max-w-2xl font-display text-display-md sm:text-display-lg">
            Your practice, without the admin
        </h1>
        <p class="mt-5 max-w-xl text-body-lg text-friend-text-secondary">
            You trained to sit with people, not to chase appointments, invoices and
            no-shows. Akilil handles the rest and stays out of the room.
        </p>
        <a href="{{ route('contact') }}" class="friend-btn mt-9">Apply to join</a>
    </section>

    <section class="mx-auto mt-16 max-w-5xl px-5 sm:px-8">
        <div class="grid gap-6 md:grid-cols-2">
            @php
                $offers = [
                    ['Your hours, honestly yours', 'Open Tuesday evenings only, or Saturday mornings before the shop gets busy. Availability is a calendar, not a commitment you have to defend.'],
                    ['Paid in birr, on time', 'Payouts to Telebirr or your bank account. Clients pay through Chapa. You see the fee before you accept a booking — no silent deductions.'],
                    ['Verified, and it shows', 'We check your identity, your licence and your references once. After that, the badge on your profile does the convincing so you do not have to.'],
                    ['No cold outreach', 'Clients arrive already matched to what you actually do. You can decline any request without explaining yourself.'],
                ];
            @endphp

            @foreach ($offers as [$title, $body])
                <article class="friend-card">
                    <h2 class="font-display text-headline-md">{{ $title }}</h2>
                    <p class="mt-2.5 text-body-md text-friend-text-secondary">{{ $body }}</p>
                </article>
            @endforeach
        </div>
    </section>

    <section class="mx-auto mt-16 max-w-5xl px-5 sm:px-8">
        <div class="rounded-friend-lg border border-friend-border bg-friend-recessed p-8 sm:p-10">
            <h2 class="font-display text-headline-lg">Who we're looking for</h2>
            <p class="mt-3 max-w-2xl text-body-md text-friend-text-secondary">
                Licensed counsellors and psychologists, spiritual guides, wellness and
                habit coaches, and trained peer listeners. Practising in Ethiopia or
                working with Ethiopian clients abroad. Warmth is not optional; the
                licence sometimes is, depending on the room you want to hold.
            </p>

            <h3 class="mt-9 font-display text-headline-md">How joining goes</h3>
            <ol class="mt-4 space-y-3 text-body-md text-friend-text-secondary">
                <li class="flex gap-3">
                    <span class="font-semibold text-friend-primary-deep">01</span>
                    You send us a short note about your practice.
                </li>
                <li class="flex gap-3">
                    <span class="font-semibold text-friend-primary-deep">02</span>
                    We talk for half an hour — a conversation, not an interrogation.
                </li>
                <li class="flex gap-3">
                    <span class="font-semibold text-friend-primary-deep">03</span>
                    Documents and references checked, usually inside a week.
                </li>
                <li class="flex gap-3">
                    <span class="font-semibold text-friend-primary-deep">04</span>
                    Your profile goes live and you pick your first hours.
                </li>
            </ol>

            <a href="{{ route('contact') }}" class="friend-btn friend-btn--accent mt-9">Start the conversation</a>
        </div>
    </section>

@endsection
