{{-- =====================================================================
      Akilil — Design System preview (Task 0.5 example screen)
      Light, brand-on-brand reference page rendering the same tokens
      that ship in packages/core/lib/src/theme/design_tokens.dart.

      Accessible at GET /design-system (route registered in
      routes/web.php). Not part of the admin panel — sits next to the
      public marketing site (Task 12) but available now for review.

      Self-contained (no layout) so it works during Task 0.5 review
      before the marketing site's layout exists. Task 12 refactors this
      into a proper layout.
      ===================================================================== --}}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Design System — Akilil</title>
    @vite(['resources/css/app.css'])
</head>
<body>
<main class="min-h-screen px-6 py-12 sm:px-10 lg:px-16">
<main class="min-h-screen px-6 py-12 sm:px-10 lg:px-16">

  <header class="max-w-4xl mx-auto mb-16">
    <p class="friend-pill friend-pill--accent mb-4">Akilil · Design System</p>
    <h1 class="font-display text-display-lg mb-3">A calm, warm surface.</h1>
    <p class="text-body-lg text-friend-text-secondary max-w-2xl">
      Light green for grounding, orange for human-connection moments.
      Generous corners, soft shadows, no harsh contrast. This is the
      system every Akilil surface renders against — admin panel, both
      mobile apps, and the public site.
    </p>
  </header>

  {{-- Palette ----------------------------------------------- --}}
  <section class="max-w-4xl mx-auto mb-16">
    <h2 class="text-headline-lg mb-6">Palette</h2>

    <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
      @php
        $swatches = [
          ['name' => 'Background',    'var' => 'var(--friend-bg)',           'hex' => '#FBFAF6', 'text' => '#1F2A22'],
          ['name' => 'Surface',       'var' => 'var(--friend-surface)',      'hex' => '#FFFFFF', 'text' => '#1F2A22'],
          ['name' => 'Recessed',      'var' => 'var(--friend-recessed)',     'hex' => '#F3F6F1', 'text' => '#1F2A22'],
          ['name' => 'Primary',       'var' => 'var(--friend-primary)',      'hex' => '#2E6B4E', 'text' => '#FFFFFF'],
          ['name' => 'Primary Soft',  'var' => 'var(--friend-primary-soft)', 'hex' => '#CDE6D6', 'text' => '#1F4A33'],
          ['name' => 'Primary Deep',  'var' => 'var(--friend-primary-deep)', 'hex' => '#1F4A33', 'text' => '#FFFFFF'],
          ['name' => 'Accent',        'var' => 'var(--friend-accent)',       'hex' => '#E8823A', 'text' => '#FFFFFF'],
          ['name' => 'Accent Deep',   'var' => 'var(--friend-accent-deep)',  'hex' => '#C96A28', 'text' => '#FFFFFF'],
          ['name' => 'Text Primary',  'var' => 'var(--friend-text-primary)', 'hex' => '#1F2A22', 'text' => '#FBFAF6'],
          ['name' => 'Text Secondary','var' => 'var(--friend-text-secondary)','hex' => '#6B7A70', 'text' => '#FBFAF6'],
          ['name' => 'Border',        'var' => 'var(--friend-border)',       'hex' => '#E4E8E1', 'text' => '#1F2A22'],
          ['name' => 'Error',         'var' => 'var(--friend-error)',        'hex' => '#C0392B', 'text' => '#FFFFFF'],
        ];
      @endphp

      @foreach ($swatches as $s)
        <div class="rounded-friend-sm border border-friend-border p-4 flex flex-col justify-end"
             style="background: {{ $s['var'] }}; color: {{ $s['text'] }}; min-height: 96px;">
          <span class="text-body-sm font-semibold">{{ $s['name'] }}</span>
          <span class="text-caption opacity-80 font-mono">{{ $s['hex'] }}</span>
        </div>
      @endforeach
    </div>
  </section>

  {{-- Type ramp ---------------------------------------------- --}}
  <section class="max-w-4xl mx-auto mb-16">
    <h2 class="text-headline-lg mb-6">Type ramp</h2>
    <div class="friend-card">
      <div class="space-y-4">
        <div class="flex items-baseline gap-4">
          <span class="text-caption text-friend-text-secondary w-28 shrink-0">display-md · Fraunces</span>
          <span class="font-display text-display-md">A platform built around presence.</span>
        </div>
        <div class="flex items-baseline gap-4">
          <span class="text-caption text-friend-text-secondary w-28 shrink-0">headline-lg · Fraunces</span>
          <span class="font-display text-headline-lg">Find the right professional for you.</span>
        </div>
        <div class="flex items-baseline gap-4">
          <span class="text-caption text-friend-text-secondary w-28 shrink-0">headline-md · Inter</span>
          <span class="font-sans text-headline-md font-semibold">Upcoming sessions</span>
        </div>
        <div class="flex items-baseline gap-4">
          <span class="text-caption text-friend-text-secondary w-28 shrink-0">body-lg · Inter</span>
          <span class="text-body-lg">Connect with verified wellness professionals over secure video sessions.</span>
        </div>
        <div class="flex items-baseline gap-4">
          <span class="text-caption text-friend-text-secondary w-28 shrink-0">body-md · Inter</span>
          <span class="text-body-md">Friendly, calm interface. Generous spacing. No dark patterns.</span>
        </div>
        <div class="flex items-baseline gap-4">
          <span class="text-caption text-friend-text-secondary w-28 shrink-0">body-sm · Inter</span>
          <span class="text-body-sm text-friend-text-secondary">Used for helper text and timestamps.</span>
        </div>
      </div>
    </div>
  </section>

  {{-- Components --------------------------------------------- --}}
  <section class="max-w-4xl mx-auto mb-16">
    <h2 class="text-headline-lg mb-6">Components</h2>

    <div class="grid sm:grid-cols-2 gap-6">
      {{-- Sample card --}}
      <div class="friend-card">
        <div class="flex items-start gap-3 mb-4">
          <div class="w-12 h-12 rounded-friend-pill bg-friend-primary-soft flex items-center justify-center">
            <span class="text-friend-primary text-xl">✦</span>
          </div>
          <div class="flex-1">
            <h3 class="font-sans text-headline-sm font-semibold mb-0.5">Dr. Maya Owens</h3>
            <p class="text-body-sm text-friend-text-secondary">Spiritual counseling · 8 yrs</p>
          </div>
          <span class="friend-pill">Verified</span>
        </div>
        <p class="text-body-md mb-5">
          Hold space for the parts of you that need rest. Together we find rhythm.
        </p>
        <div class="flex gap-3">
          <button class="bg-friend-primary text-friend-on-primary px-5 py-3 rounded-friend font-semibold text-body-md">
            Book session
          </button>
          <button class="border border-friend-border text-friend-primary px-5 py-3 rounded-friend font-semibold text-body-md">
            View profile
          </button>
        </div>
      </div>

      {{-- Sample input + chips --}}
      <div class="friend-card">
        <label class="block text-body-sm font-medium text-friend-text-secondary mb-1.5">Email</label>
        <input
          type="email"
          placeholder="you@example.com"
          class="w-full bg-friend-recessed border border-friend-border rounded-friend px-4 py-3 text-body-md focus:outline-none focus:ring-2 focus:ring-friend-primary"
        />

        <label class="block text-body-sm font-medium text-friend-text-secondary mt-5 mb-2">Categories</label>
        <div class="flex flex-wrap gap-2">
          <span class="friend-pill">Therapy</span>
          <span class="friend-pill">Fitness</span>
          <span class="friend-pill friend-pill--accent">Cooking ✦</span>
          <span class="friend-pill">Spiritual</span>
          <span class="friend-pill">Habits</span>
        </div>
      </div>
    </div>
  </section>

  <footer class="max-w-4xl mx-auto text-body-sm text-friend-text-secondary border-t border-friend-border pt-6">
    Tokens defined in <code class="font-mono">resources/css/friend-tokens.css</code> ·
    Flutter mirror in <code class="font-mono">packages/core/lib/src/theme/design_tokens.dart</code>
  </footer>
</main>
</body>
</html>