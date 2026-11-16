import defaultTheme from 'tailwindcss/defaultTheme';
import colors from 'tailwindcss/colors';

/** @type {import('tailwindcss').Config} */
export default {
    content: [
        './vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php',
        './storage/framework/views/*.php',
        './resources/**/*.blade.php',
        './resources/**/*.js',
        './resources/**/*.vue',
    ],
    darkMode: ['class', '[data-theme="dark"]'],
    theme: {
        extend: {
            colors: {
                /* Friend brand palette — mirrors packages/core/lib/src/theme/design_tokens.dart.
                 * Use these utility classes in Blade views / Filament overrides:
                 *   bg-friend-primary, text-friend-text-secondary, border-friend-border … */
                friend: {
                    bg:            'var(--friend-bg)',
                    surface:       'var(--friend-surface)',
                    recessed:      'var(--friend-recessed)',

                    primary:       'var(--friend-primary)',
                    'primary-soft':'var(--friend-primary-soft)',
                    'primary-deep':'var(--friend-primary-deep)',
                    'on-primary':  'var(--friend-on-primary)',

                    accent:        'var(--friend-accent)',
                    'accent-deep': 'var(--friend-accent-deep)',
                    'on-accent':   'var(--friend-on-accent)',

                    aqua:          'var(--friend-aqua)',
                    'aqua-soft':   'var(--friend-aqua-soft)',

                    text: {
                        DEFAULT:  'var(--friend-text-primary)',
                        primary:  'var(--friend-text-primary)',
                        secondary:'var(--friend-text-secondary)',
                        muted:    'var(--friend-text-muted)',
                        inverse:  'var(--friend-text-inverse)',
                    },

                    border:  'var(--friend-border)',
                    divider: 'var(--friend-divider)',

                    error:    'var(--friend-error)',
                    'error-bg':'var(--friend-error-bg)',
                    info:     'var(--friend-info)',
                    success:  'var(--friend-primary)',
                },
            },
            fontFamily: {
                /* Display = Fraunces (serif); Body = Inter (sans). */
                display: ['Fraunces', ...defaultTheme.fontFamily.serif],
                sans:    ['Inter',    ...defaultTheme.fontFamily.sans],
            },
            fontSize: {
                /* Matches the Flutter type scale 1:1. */
                'display-lg':   ['2.5rem',   { lineHeight: '1.15', letterSpacing: '-0.01em' }],
                'display-md':   ['2rem',     { lineHeight: '1.20', letterSpacing: '-0.01em' }],
                'display-sm':   ['1.75rem',  { lineHeight: '1.25', letterSpacing: '-0.01em' }],
                'headline-lg':  ['1.5rem',   { lineHeight: '1.30' }],
                'headline-md':  ['1.25rem',  { lineHeight: '1.35' }],
                'headline-sm':  ['1.125rem', { lineHeight: '1.40' }],
                'body-lg':      ['1rem',     { lineHeight: '1.55' }],
                'body-md':      ['0.875rem', { lineHeight: '1.55' }],
                'body-sm':      ['0.75rem',  { lineHeight: '1.50' }],
                'caption':      ['0.6875rem',{ lineHeight: '1.40', letterSpacing: '0.04em' }],
            },
            borderRadius: {
                friend: 'var(--friend-radius-md)',
                'friend-sm': 'var(--friend-radius-sm)',
                'friend-lg': 'var(--friend-radius-lg)',
                'friend-pill': 'var(--friend-radius-pill)',
            },
            boxShadow: {
                'friend-card':   'var(--friend-shadow-card)',
                'friend-button': 'var(--friend-shadow-button)',
                'friend-pop':    'var(--friend-shadow-pop)',
            },
            ringColor: {
                'friend-focus': 'var(--friend-primary)',
            },
        },
    },
    plugins: [],
};