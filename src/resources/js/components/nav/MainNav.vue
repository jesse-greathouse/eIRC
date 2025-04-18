<!-- src/resources/js/components/nav/MainNav.vue -->
<template>
    <nav class="bg-white dark:bg-gray-900 px-4 py-3 flex items-center justify-between">
        <div class="flex items-center space-x-4">
            <Link href="/" class="font-bold text-lg">eIRC</Link>
            <Link href="/chat" class="hover:underline">Chat</Link>
            <Link href="/settings" class="hover:underline">Settings</Link>
        </div>
    </nav>
</template>

<script setup lang="ts">
import { Link } from '@inertiajs/vue3';
</script>
