# Akilil Platform — Style Guide

> **Task 0.5 deliverable.** The single visual reference document for
> every surface in the Akilil Platform — the User app, the Professional
> app, the admin dashboard, and the public marketing site (Task 12).
>
> **Rule:** never hardcode a hex, a corner radius, or a font size
> anywhere outside the token files. If a screen needs a new value,
> add it as a token here first.
>
> ---
> **Token sources (the only places values are allowed to live):**
> - **Web:** `friend-backend/resources/css/friend-tokens.css` (CSS custom properties) + `friend-backend/tailwind.config.js`
> - **Flutter:** `packages/core/lib/src/theme/design_tokens.dart`
>
> Both files import from the same source-of-truth values documented
> below. If you change one, change the other.

---

## 1. Brand voice

**Akilil** is a wellness and human-connection platform. The visual
identity should feel:

- **Calm** — candy-cream surfaces, generous whitespace, no flashing
  CTAs, no urgency language.
- **Trustworthy** — smooth green signals "safe / confirmed / healthy";
  no garish rainbows, no dark patterns, no aggressive reds.
- **Warm** — sunset orange is the "human-connection" note;
  reserved for booking confirmations, professional badges,
  streaks, and achievement moments. Aqua is for reflection (journal, mood).
- **Approachable** — soft 12–20px corners, low-opacity shadows,
  friendly rounded display serif (Fraunces) paired with a clean humanist
  sans (Inter). Never sharp/corporate.

If a screen feels like a SaaS dashboard, the design has drifted. Reset
against this section.

---

## 2. Palette

| Token | Light | Dark | Use |
|-------|-------|------|-----|
| `--friend-bg` | `#FFF7F2` (candy cream) | `#101816` | App / page background. Never `#FFFFFF` — softer on the eyes. |
| `--friend-surface` | `#FFFFFF` | `#1A2421` | Cards, sheets, dialogs. |
| `--friend-recessed` | `#EEF9F6` | `#222E2A` | Recessed wells (form fields, search bars). |
| `--friend-primary` | `#3ECF8E` | `#5FE0A8` | Primary buttons, active states, "safe/healthy" icons, success. |
| `--friend-primary-soft` | `#C5F5DE` | `#2A8F62` | Tag backgrounds, progress bars, subtle highlights. |
| `--friend-primary-deep` | `#2A8F62` | `#5FE0A8` | Hover/pressed on primary buttons. |
| `--friend-on-primary` | `#FFFFFF` | `#101816` | Text/icon on top of primary. |
| `--friend-accent` | `#FF8B5C` | unchanged | "Book now", booking confirmations, verified badges, streaks. Sparingly. |
| `--friend-accent-deep` | `#F06A3A` | unchanged | Hover/pressed on accent buttons. |
| `--friend-on-accent` | `#FFFFFF` | `#101816` | Text/icon on top of accent. |
| `--friend-aqua` | `#7EE8DE` | `#7EE8DE` | Journal, mood, informational washes. |
| `--friend-aqua-soft` | `#D4F5F1` | `#1E3A36` | Soft aqua wells. |
| `--friend-text-primary` | `#1E2F2A` | `#EFF8F4` | Near-black with a green tint — never pure black. |
| `--friend-text-secondary` | `#5F7A72` | `#B0C7BE` | Helper text, captions, metadata. |
| `--friend-text-muted` | `#95AFA7` | `#7E8B84` | Disabled text, very low-priority labels. |
| `--friend-border` | `#D9EBE5` | `#2A3833` | Card borders, input borders. |
| `--friend-divider` | `#EEF5F2` | `#222E2A` | Hairline dividers, table row separators. |
| `--friend-error` | `#E85D5D` | `#F08A8A` | Destructive actions only. **Never use this for general warning UI**. |
| `--friend-info` | `#5BCFC6` | `#7EE8DE` | Neutral informational, e.g. "we sent you an email". |

### Component rule — green vs orange
> Never use orange and green at equal visual weight in the same
> component. One is the dominant color, the other is the accent.
>
> - A **primary action button** is green. The badge "verified" can be
>   green or orange, but not both stacked.
> - A **booking confirmation** page is white with a single orange
>   header banner — no extra green callouts in the same hero.
> - **Achievements / streaks** are orange. Health / confirmation
>   moments are green.

---

## 3. Typography

### Display: **Fraunces** (variable, opsz 9–144)
A warm, slightly rounded humanist serif. Used **only** for:
- Hero headlines
- Section / screen titles
- Marketing landing-page H1s

Never on body copy, buttons, form fields, or table cells.

### Body: **Inter**
A clean, highly legible humanist sans. Used for:
- All body copy
- Form labels, inputs, helper text
- Buttons (labelLarge / font-weight 600)
- Table cells, list items, dense admin data

### Scale (matches across all surfaces)

| Token | px | Use |
|-------|-----|-----|
| `display-lg` | 40 | Marketing hero H1 only |
| `display-md` | 32 | Screen hero / landing H1 |
| `display-sm` | 28 | Empty-state hero |
| `headline-lg` | 24 | Section H2 / modal title |
| `headline-md` | 20 | Card / list-section title |
| `headline-sm` | 18 | In-page sub-section |
| `body-lg` | 16 | Body copy emphasis |
| `body-md` | 14 | Default body |
| `body-sm` | 12 | Helper text, timestamps |
| `caption` | 11 | All-caps utility labels (rare) |

Tailwind aliases: `text-display-lg`, `text-body-md`, … mirror these exactly.

Flutter: `Theme.of(context).textTheme.displayLarge`, `.bodyMedium`, etc.

---

## 4. Shape & elevation

### Radii

| Token | Value | Use |
|-------|-------|-----|
| `friend-radius-sm` | 12px | Inputs, small chips, secondary buttons |
| `friend-radius-md` | 16px | Cards, primary buttons (default) |
| `friend-radius-lg` | 20px | Hero cards, marketing panels |
| `friend-radius-pill` | 999px | Verified badge, pill buttons, avatar containers |

Anything sharper than 12px looks corporate — don't go there.

### Shadows (low opacity, soft, primary-tinted)

| Token | Value | Use |
|-------|-------|-----|
| `--friend-shadow-card` | `0 4px 16px 0 rgba(46,107,78,0.08)` | Default card lift |
| `--friend-shadow-button` | `0 2px 8px 0 rgba(46,107,78,0.10)` | Pressed/hover button |
| `--friend-shadow-pop` | `0 8px 24px 0 rgba(46,107,78,0.12)` | Modal / popover |

No hard drop shadows. No double shadows. No `0 0 0 1px` borders-as-shadows.

---

## 5. Component states

Every interactive component has four canonical states. The token
mapping is the same across Flutter and web:

| State | Background | Border | Text | Shadow |
|-------|------------|--------|------|--------|
| **Default** | `primary` | none | `on-primary` | none |
| **Hover** | `primary-deep` | none | `on-primary` | `friend-shadow-button` |
| **Pressed** | `primary-deep` | none | `on-primary` | inset `0 2px 4px rgba(0,0,0,0.1)` |
| **Disabled** | `recessed` | `border` | `text-muted` | none |

Same matrix for accent buttons (substitute `accent` for `primary`).

---

## 6. Iconography

- **Single icon set across all four surfaces.** Recommended: **Phosphor**
  (rounded variant) — its corner radius matches the 12-20px language.
  Lucide is a fine backup.
- **Stroke weight:** 1.5pt at 24×24. Never use filled icons in the
  default state — reserved for "selected" toggles only.
- **Size scale:** 16, 20, 24, 32. Default is 24.
- Icons that signal "safe / confirmed / healthy" are tinted `primary`.
  Icons that signal "human / social / achievement" can use `accent`.

---

## 7. Empty / loading / error states

Every screen has three non-data states. The design system ships a
default for each:

- **Loading:** soft primary-soft pulse over a card-shaped placeholder.
  No spinners for content that takes >500ms — too stressful on a
  wellness product.
- **Empty:** a small inline illustration in primary-soft tones (no new
  colors introduced), a one-line headline in `headline-md`, a one-line
  subhead in `body-md` secondary, and one CTA in primary green.
- **Error:** a friend-card with the destructive red (kept OUTSIDE the
  warm palette), a short headline explaining what happened in
  human language, and a single retry button. **No** technical stack
  traces in the user-facing UI.

Crisis-flag and safety states (Task 5) sit on their own — see
ARCHITECTURE.md §8 / that task's brief for the special handling.

---

## 8. Example screens rendered against this system

The design system ships three reference renderings — one per surface —
so every future screen can be checked against a known-good example:

### Screen A — Professional card (User app "Discovery")
- **Flutter widget:** `packages/core/lib/src/theme/design_system_preview.dart`
  (the `_SampleCard` widget).
- **Web equivalent:** `friend-backend/resources/views/design-system.blade.php`
  ("Components" section, first card).
- Shows: avatar in primary-soft, primary name, verified badge, body
  copy, primary + secondary buttons, all with correct radii/shadows.

### Screen B — Form with chips (User app onboarding)
- **Flutter widget:** `_SampleInput` + `_SampleChipRow` in the same file.
- **Web equivalent:** "Components" section, second card in the same
  Blade view.
- Shows: input on recessed surface, focus ring (primary @35%),
  chips in primary-soft + accent variants.

### Screen C — Design system reference page (web)
- **Blade view:** `friend-backend/resources/views/design-system.blade.php`
  served at `/design-system`.
- Used during development to confirm tokens render correctly across
  browsers. Removed in production builds (Task 11).

A live Flutter preview is exposed by navigating to
`DesignSystemPreviewScreen` from any of the apps (wired in Task 7/8
under "Settings → Design System").

---

## 9. Localization note

The type scale and palette are **locale-independent**. The component
density and copy length are not — when localization is wired in
Task 7/8, expect Amharic / Tigrinya / Oromo strings to need
~15–25% more horizontal space at the same point size. The
design-system tokens don't change; spacing rules might need to flex.

---

## 10. What we explicitly did **not** do

- **No dark mode by default.** A toggle exists (User + Pro app, Task 7/8)
  and the admin dashboard supports `[data-theme="dark"]` for power users,
  but the brief is unambiguous: wellness products default to light.
- **No multi-color gradients.** Gradient = drift toward SaaS feel.
- **No emoji as UI icons.** Emoji is fine inside copy (vent posts,
  journal entries) but not in chrome.
- **No animation beyond 250ms.** Anything slower reads as sluggish on
  a calm product; anything faster reads as anxious.
- **No third accent colors introduced per-screen.** If a screen needs
  a fourth color, it's almost certainly the wrong design.

---

## 11. Reviewing this guide

When reviewing any new screen before merge:
1. **Palette:** only the 16 tokens above are used. If you see a hex
   in the diff that isn't in the table, block the PR.
2. **Type:** sizes match the scale. If a text style is custom and not
   in the scale, block the PR.
3. **Shape:** corners are 12/16/20 or pill. Anything else blocks.
4. **Component states:** default + hover + pressed + disabled all
   accounted for.
5. **Icons:** from Phosphor or Lucide, never ad-hoc SVG.
6. **Empty / loading / error** states exist and match §7.
7. **Brand voice:** no urgency language, no dark patterns, no
   "premium" tricks. The wellness promise holds.