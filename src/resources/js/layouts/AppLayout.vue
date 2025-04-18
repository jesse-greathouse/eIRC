<script setup lang="ts">
import AppMainLayout from '@/layouts/app/AppMainLayout.vue';
import type { BreadcrumbItemType } from '@/types';

interface Props {
    breadcrumbs?: BreadcrumbItemType[];
}

withDefaults(defineProps<Props>(), {
    breadcrumbs: () => [],
});
</script>

<template>
    <AppMainLayout :breadcrumbs="breadcrumbs">
        <slot />
    </AppMainLayout>
</template>
