import defaultTheme from 'tailwindcss/defaultTheme';

/** @type {import('tailwindcss').Config} */
export default {
    darkMode: ['class'],
    content: [
        './vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php',
        './storage/framework/views/*.php',
        './resources/views/**/*.blade.php',
        './resources/js/**/*.{vue,js,ts,jsx,tsx}',
        './node_modules/flowbite/**/*.js',
    ],
    theme: {
        extend: {
            fontFamily: {
                // Used by Tailwind's `font-sans`
                sans: [
                    'Roboto',
                    'Instrument Sans',
                    ...defaultTheme.fontFamily.sans,
                ],
                // Available for manual use via `font-poppins`
                poppins: ['Poppins', ...defaultTheme.fontFamily.sans],
            },
            borderRadius: {
                lg: 'var(--radius)',
                md: 'calc(var(--radius) - 2px)',
                sm: 'calc(var(--radius) - 4px)',
            },
            colors: {
                background: 'hsl(var(--background))',
                foreground: 'hsl(var(--foreground))',
                card: {
                    DEFAULT: 'hsl(var(--card))',
                    foreground: 'hsl(var(--card-foreground))',
                },
                popover: {
                    DEFAULT: 'hsl(var(--popover))',
                    foreground: 'hsl(var(--popover-foreground))',
                },
                primary: {
                    DEFAULT: 'hsl(var(--primary))',
                    foreground: 'hsl(var(--primary-foreground))',
                },
                secondary: {
                    DEFAULT: 'hsl(var(--secondary))',
                    foreground: 'hsl(var(--secondary-foreground))',
                },
                muted: {
                    DEFAULT: 'hsl(var(--muted))',
                    foreground: 'hsl(var(--muted-foreground))',
                },
                accent: {
                    DEFAULT: 'hsl(var(--accent))',
                    foreground: 'hsl(var(--accent-foreground))',
                },
                destructive: {
                    DEFAULT: 'hsl(var(--destructive))',
                    foreground: 'hsl(var(--destructive-foreground))',
                },
                border: 'hsl(var(--border))',
                input: 'hsl(var(--input))',
                ring: 'hsl(var(--ring))',
                chart: {
                    1: 'hsl(var(--chart-1))',
                    2: 'hsl(var(--chart-2))',
                    3: 'hsl(var(--chart-3))',
                    4: 'hsl(var(--chart-4))',
                    5: 'hsl(var(--chart-5))',
                },
                sidebar: {
                    DEFAULT: 'hsl(var(--sidebar-background))',
                    foreground: 'hsl(var(--sidebar-foreground))',
                    primary: 'hsl(var(--sidebar-primary))',
                    'primary-foreground': 'hsl(var(--sidebar-primary-foreground))',
                    accent: 'hsl(var(--sidebar-accent))',
                    'accent-foreground': 'hsl(var(--sidebar-accent-foreground))',
                    border: 'hsl(var(--sidebar-border))',
                    ring: 'hsl(var(--sidebar-ring))',
                },
            },
        },
    },
    plugins: [
        require('@tailwindcss/typography'),
        require('tailwindcss-animate'),
        require('flowbite/plugin'),
    ],
    safelist: [
        { pattern: /max-h-./ },
        { pattern: /max-w-./ },
        { pattern: /space-./ },
        { pattern: /m-./ },
        { pattern: /mt-./ },
        { pattern: /me-./ },
        { pattern: /mr-./ },
        { pattern: /ml-./ },
        { pattern: /mb-./ },
        { pattern: /p-./ },
        { pattern: /px-./ },
        { pattern: /py-./ },
        { pattern: /pl-./ },
        { pattern: /pr-./ },
        { pattern: /font-./ },
        { pattern: /text-./ },
        { pattern: /bg-./ },
        { pattern: /from-./ },
        { pattern: /to-./ },
        { pattern: /shadow-./ },
        { pattern: /transition-./ },
        { pattern: /duration-./ },
        { pattern: /ease-./ },
        { pattern: /scale-./ },
        { pattern: /rounded-./ },
        //{ pattern: /-./ },

        // Layout
        'overflow-hidden', 'list-decimal',
        // Fonts
        'font-size', 'text-xs', 'text-base', 'text-xl', 'font-poppins', 'font-roboto', 'font-sans', 'leading-relaxed',
        // Effects
        'tracking-tight',,
        // Transition
        'transition',
    ],
};
