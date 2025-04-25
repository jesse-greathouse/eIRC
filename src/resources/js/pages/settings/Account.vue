<script setup lang="ts">
import { Head, Link, useForm } from '@inertiajs/vue3';

import HeadingSmall from '@/components/HeadingSmall.vue';
import InputError from '@/components/InputError.vue';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import AppLayout from '@/layouts/AppLayout.vue';
import SettingsLayout from '@/layouts/settings/Layout.vue';
import DeleteUser from '@/components/DeleteUser.vue';
import { type BreadcrumbItem, type User } from '@/types';

interface Props {
    mustVerifyEmail: boolean;
    status?: string;
    user: User;
}

const props = defineProps<Props>();

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Account settings', href: '/settings/account' },
];

const formUser = useForm({
    name: props.user.name,
    email: props.user.email,
    nick: props.user.nick || '',
});

const submitUser = () => {
    formUser.put(route('api.user.update'), { preserveScroll: true });
};
</script>

<template>
    <AppLayout :breadcrumbs="breadcrumbs">

        <Head title="Account settings" />

        <SettingsLayout>
            <div class="flex flex-col space-y-10">
                <HeadingSmall title="Account Information" description="Update your name, email, and IRC nickname" />
                <form @submit.prevent="submitUser" class="space-y-6">
                    <div class="grid gap-2">
                        <Label for="name">Name</Label>
                        <Input id="name" v-model="formUser.name" required />
                        <InputError class="mt-2" :message="formUser.errors.name" />
                    </div>

                    <div class="grid gap-2">
                        <Label for="email">Email address</Label>
                        <Input id="email" type="email" v-model="formUser.email" required />
                        <InputError class="mt-2" :message="formUser.errors.email" />
                    </div>

                    <div v-if="mustVerifyEmail && !props.user.email_verified_at">
                        <p class="-mt-4 text-sm text-muted-foreground">
                            Your email address is unverified.
                            <Link :href="route('verification.send')" method="post" as="button">
                            Click here to resend the verification email.
                            </Link>
                        </p>
                        <div v-if="status === 'verification-link-sent'" class="mt-2 text-sm font-medium text-green-600">
                            A new verification link has been sent to your email address.
                        </div>
                    </div>

                    <div class="grid gap-2">
                        <Label for="nick">IRC Nickname</Label>
                        <Input id="nick" v-model="formUser.nick" placeholder="e.g., jesse123" />
                        <InputError class="mt-2" :message="formUser.errors.nick" />
                    </div>

                    <div class="flex items-center gap-4">
                        <Button :disabled="formUser.processing">Save Account Info</Button>
                        <p v-show="formUser.recentlySuccessful" class="text-sm text-neutral-600">Saved.</p>
                    </div>

                    <DeleteUser />
                </form>
            </div>
        </SettingsLayout>
    </AppLayout>
</template>
