@extends('marketing.layout')

@section('title', 'Terms')
@section('description', 'The agreement between you and Akilil, in plain language. Draft ahead of launch.')

@section('content')

    <section class="mx-auto max-w-3xl px-5 pt-16 sm:px-8 sm:pt-24">
        <span class="friend-pill">Draft · last updated 12 August 2026</span>
        <h1 class="mt-6 font-display text-display-md sm:text-display-lg">Terms of use</h1>
        <p class="mt-5 text-body-lg text-friend-text-secondary">
            Written to be read, not to be survived. This is a draft while we are in beta;
            the reviewed version arrives before we open to everyone.
        </p>
    </section>

    <section class="mx-auto mt-10 max-w-3xl px-5 sm:px-8">
        <div class="friend-card space-y-9">
            @php
                $sections = [
                    ['Who can use Akilil', 'You need to be 18 or older and give us accurate details when you sign up. One account per person — sharing an account means the professional cannot know who they are actually talking to.'],
                    ['What Akilil is', 'A place to talk to listeners and wellness professionals, plus a private journal and moderated community rooms. Akilil is not a medical or emergency service, does not diagnose, and does not prescribe. Read the safety page before you rely on us for anything urgent.'],
                    ['The professionals', 'Professionals on Akilil are independent practitioners, not our employees. We verify identity, licences and references, and we remove people who break our rules. The care itself is between you and them.'],
                    ['Paying and cancelling', 'Prices are shown in birr before you pay, through Chapa or Telebirr. Subscriptions run month to month and you can cancel in the app at any time; you keep access until the end of the month you already paid for. Unused sessions do not roll over.'],
                    ['Missed sessions', 'Cancel more than four hours ahead and it costs you nothing. Later than that, or a no-show, and the session counts as used — the professional held that hour for you.'],
                    ['How to behave here', 'No harassment, no threats, no recording a session without consent, no selling anything to other members, no pretending to be a licensed professional. We close accounts for these, without a refund of the current month.'],
                    ['Your writing stays yours', 'You own what you write. You give us only the narrow permission needed to store it and show it to you and, for messages, to the person you sent it to. See the privacy page.'],
                    ['When things go wrong', 'We keep Akilil running as carefully as we can, but we cannot promise it will never be down. Our responsibility is limited to what you paid us in the previous three months. Nothing here removes rights you have under Ethiopian law.'],
                    ['Changes and closing accounts', 'If we change these terms in a way that matters, we will tell you in the app at least 14 days ahead. You can close your account whenever you like, for any reason, without telling us why.'],
                    ['Governing law', 'These terms are governed by the laws of the Federal Democratic Republic of Ethiopia, and disputes are heard in the courts of Addis Ababa.'],
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
                Questions about any clause?
                <a href="{{ route('contact') }}" class="font-semibold">Ask us</a> — we would
                rather explain it now than argue about it later.
            </p>
        </div>
    </section>

@endsection
