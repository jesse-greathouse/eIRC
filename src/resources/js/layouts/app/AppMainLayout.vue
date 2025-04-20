<template>
    <div class="h-screen flex flex-col overflow-hidden bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white">
        <!-- Fixed height header -->
        <header class="h-14 shrink-0 shadow z-20">
            <MainNav />
        </header>

        <!-- Fill remaining height -->
        <main class="flex-1 flex flex-col min-h-0 p-4 overflow-hidden">
            <slot />
        </main>
    </div>
</template>

<script setup lang="ts">
import MainNav from '@/components/nav/MainNav.vue';
</script>
