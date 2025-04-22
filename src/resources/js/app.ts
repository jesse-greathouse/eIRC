import '../css/flowbite.css';
import '../css/app.css';

import { createInertiaApp } from '@inertiajs/vue3';
import { resolvePageComponent } from 'laravel-vite-plugin/inertia-helpers';
import type { DefineComponent } from 'vue';
import { createApp, h } from 'vue';
import { ZiggyVue } from 'ziggy-js';
import { initFlowbite } from 'flowbite';
import { initializeTheme } from './composables/useAppearance';

import { useIrcClient } from './composables/useIrcClient';

const appName = import.meta.env.VITE_APP_NAME || 'Laravel';

createInertiaApp({
    title: (title) => `${title} - ${appName}`,
    resolve: (name) => resolvePageComponent(`./pages/${name}.vue`, import.meta.glob<DefineComponent>('./pages/**/*.vue')),
    setup({ el, App, props, plugin }) {
        createApp({ render: () => h(App, props) })
            .use(plugin)
            .use(ZiggyVue)
            .mount(el);

        // 🌐 Initialize global IRC client if token is available
        const rawToken = props.initialPage.props.chat_token;
        const chatToken = typeof rawToken === 'string' ? rawToken : null;

        if (chatToken) {
            try {
                useIrcClient(chatToken);
            } catch (error) {
                console.warn('[IRC] Failed to initialize client:', error);
            }
        }

        // 🎨 Theme and Flowbite setup
        initFlowbite();
        initializeTheme();
    },
    progress: {
        color: '#4B5563',
    },
});
