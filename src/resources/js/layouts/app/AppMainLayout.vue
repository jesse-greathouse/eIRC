<template>
    <div class="min-h-screen flex flex-col bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white">
        <!-- Top Global Navigation -->
        <header class="shadow z-20">
            <MainNav />
        </header>

        <!-- Main Content Area -->
        <main class="flex flex-1 min-h-0 p-4 overflow-hidden">
            <slot />
        </main>
    </div>
</template>

<script setup lang="ts">
import MainNav from '@/components/nav/MainNav.vue';
</script>
