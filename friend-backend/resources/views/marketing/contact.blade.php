@extends('marketing.layout')

@section('title', 'Contact')
@section('description', 'Write to us. A person reads every message and replies within two working days.')

@section('content')

    <section class="mx-auto max-w-3xl px-5 pt-16 sm:px-8 sm:pt-24">
        <span class="friend-pill">Replies from a human, within two working days</span>
        <h1 class="mt-6 font-display text-display-md sm:text-display-lg">Write to us</h1>
        <p class="mt-5 text-body-lg text-friend-text-secondary">
            Joining as a professional, a question about the beta, a safety concern, or
            something we got wrong — all of it lands in the same inbox.
        </p>
    </section>

    <section class="mx-auto mt-10 max-w-3xl px-5 pb-4 sm:px-8">
        <div class="friend-card">
            @if ($errors->any())
                <div class="mb-6 rounded-friend-sm border border-friend-error bg-friend-error-bg p-4">
                    <p class="text-body-md font-medium text-friend-error">
                        Almost — please check the fields below.
                    </p>
                </div>
            @endif

            <form method="POST" action="{{ route('contact.send') }}" class="space-y-5">
                @csrf

                <div>
                    <label for="name" class="friend-label">Your name</label>
                    <input id="name" name="name" type="text" required autocomplete="name"
                           value="{{ old('name') }}"
                           placeholder="Selam Bekele"
                           class="friend-input @error('name') friend-input--invalid @enderror">
                    @error('name')
                        <p class="mt-1.5 text-body-sm text-friend-error">{{ $message }}</p>
                    @enderror
                </div>

                <div>
                    <label for="email" class="friend-label">Email</label>
                    <input id="email" name="email" type="email" required autocomplete="email"
                           value="{{ old('email') }}"
                           placeholder="you@example.com"
                           class="friend-input @error('email') friend-input--invalid @enderror">
                    @error('email')
                        <p class="mt-1.5 text-body-sm text-friend-error">{{ $message }}</p>
                    @enderror
                </div>

                <div>
                    <label for="topic" class="friend-label">What's this about? <span class="text-friend-text-muted">(optional)</span></label>
                    <select id="topic" name="topic" class="friend-input">
                        <option value="">Choose one</option>
                        <option value="joining" @selected(old('topic') === 'joining')>Joining as a professional</option>
                        <option value="beta" @selected(old('topic') === 'beta')>Getting into the beta</option>
                        <option value="safety" @selected(old('topic') === 'safety')>A safety concern</option>
                        <option value="press" @selected(old('topic') === 'press')>Press or partnership</option>
                        <option value="other" @selected(old('topic') === 'other')>Something else</option>
                    </select>
                </div>

                <div>
                    <label for="message" class="friend-label">Your message</label>
                    <textarea id="message" name="message" rows="6" required
                              placeholder="Take as much space as you need."
                              class="friend-input @error('message') friend-input--invalid @enderror">{{ old('message') }}</textarea>
                    @error('message')
                        <p class="mt-1.5 text-body-sm text-friend-error">{{ $message }}</p>
                    @enderror
                </div>

                <div class="flex flex-wrap items-center gap-4 pt-1">
                    <button type="submit" class="friend-btn">Send it</button>
                    <p class="text-body-sm text-friend-text-muted">
                        We never add you to a mailing list from this form.
                    </p>
                </div>
            </form>
        </div>
    </section>

    <section class="mx-auto mt-8 max-w-3xl px-5 sm:px-8">
        <div class="rounded-friend-lg border border-friend-border bg-friend-recessed p-8">
            <h2 class="font-display text-headline-md">If a form feels too formal</h2>
            <p class="mt-2.5 text-body-md text-friend-text-secondary">
                Email <span class="font-medium text-friend-text-primary">hello@akilil.app</span> —
                or find us on Telegram, where most of our beta conversations actually
                happen. Handle coming as soon as the channel is public.
            </p>
            <p class="mt-4 text-body-sm text-friend-text-muted">
                Urgent safety matters: please read our
                <a href="{{ route('safety') }}" class="font-semibold">safety page</a> first —
                a form is not fast enough for an emergency.
            </p>
        </div>
    </section>

@endsection
