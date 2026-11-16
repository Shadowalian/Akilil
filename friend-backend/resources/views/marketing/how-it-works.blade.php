@extends('marketing.layout')

@section('title', 'How it works')
@section('description', 'Four steps: say what is going on, get matched, talk however you like, and keep the thread.')

@section('content')

    <section class="mx-auto max-w-3xl px-5 pt-16 sm:px-8 sm:pt-24">
        <span class="friend-pill">Four steps, no forms to dread</span>
        <h1 class="mt-6 font-display text-display-md sm:text-display-lg">How it works</h1>
        <p class="mt-5 text-body-lg text-friend-text-secondary">
            You should be talking to someone within a day of downloading the app.
            That's the whole design brief.
        </p>
    </section>

    <section class="mx-auto mt-14 max-w-3xl px-5 sm:px-8">
        <ol class="space-y-5">
            @php
                $steps = [
                    [
                        'title' => 'Tell us what today feels like',
                        'body'  => 'One sentence is enough. Pick a mood, or type the thing you would text a friend at 11pm. No intake questionnaire, no diagnosis dropdown.',
                    ],
                    [
                        'title' => 'We find you a person',
                        'body'  => 'We match on language, on what you are dealing with, and on who is actually free now — not on whoever paid for placement. You see their name, their photo and their real experience before you say yes.',
                    ],
                    [
                        'title' => 'Talk your way',
                        'body'  => 'Chat if your voice is shaking. Voice if typing is too slow. Video if you want to see a face. Switch mid-session; nobody will mind.',
                    ],
                    [
                        'title' => 'Keep the thread',
                        'body'  => 'Your notes, moods and habits stay in one private place, so the next conversation does not start from zero. Come back next week, or next season.',
                    ],
                ];
            @endphp

            @foreach ($steps as $i => $step)
                <li class="friend-card flex gap-5">
                    <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-friend-pill bg-friend-primary text-body-md font-semibold text-friend-on-primary">
                        {{ $i + 1 }}
                    </span>
                    <div>
                        <h2 class="font-display text-headline-md">{{ $step['title'] }}</h2>
                        <p class="mt-2 text-body-md text-friend-text-secondary">{{ $step['body'] }}</p>
                    </div>
                </li>
            @endforeach
        </ol>
    </section>

    <section class="mx-auto mt-14 max-w-3xl px-5 sm:px-8">
        <div class="rounded-friend-lg border border-friend-border bg-friend-recessed p-8">
            <h2 class="font-display text-headline-lg">What it costs to begin</h2>
            <p class="mt-2.5 text-body-md text-friend-text-secondary">
                Nothing. The journal, the community rooms and your first conversation
                are free. When you want regular sessions, you pay in birr through
                Chapa or Telebirr — and only then.
            </p>
            <div class="mt-7 flex flex-wrap gap-3">
                <a href="{{ route('download') }}" class="friend-btn">Get the app</a>
                <a href="{{ route('pricing') }}" class="friend-btn friend-btn--ghost">See pricing</a>
            </div>
        </div>
    </section>

@endsection
