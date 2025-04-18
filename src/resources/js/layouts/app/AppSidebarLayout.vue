<script setup lang="ts">
import AppMainLayout from '@/layouts/app/AppMainLayout.vue';

withDefaults(defineProps<{
    breadcrumbs?: unknown[];
}>(), {
    breadcrumbs: () => [],
});
</script>

<template>
    <AppMainLayout :breadcrumbs="breadcrumbs" :showContextMenu="true">
        <slot />
    </AppMainLayout>
</template>
