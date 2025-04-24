<script setup lang="ts">
import { Head, Link, useForm, usePage } from '@inertiajs/vue3';

import DeleteUser from '@/components/DeleteUser.vue';
import HeadingSmall from '@/components/HeadingSmall.vue';
import InputError from '@/components/InputError.vue';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import AppLayout from '@/layouts/AppLayout.vue';
import SettingsLayout from '@/layouts/settings/Layout.vue';
import { type BreadcrumbItem, type User, type Profile } from '@/types';

interface Props {
    mustVerifyEmail: boolean;
    status?: string;
    user: User;
    profile: Profile;
}

const props = defineProps<Props>();

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Profile settings', href: '/settings/profile' },
];

const formUser = useForm({
    name: props.user.name,
    email: props.user.email,
    nick: props.user.nick || '',
});

const formProfile = useForm({
    timezone: props.profile.timezone || 'UTC',
    bio: props.profile.bio || '',
    x_link: props.profile.x_link || '',
    instagram_link: props.profile.instagram_link || '',
    tiktok_link: props.profile.tiktok_link || '',
    youtube_link: props.profile.youtube_link || '',
    facebook_link: props.profile.facebook_link || '',
    pinterest_link: props.profile.pinterest_link || '',
});

const submitUser = () => {
    formUser.put(route('api.user.update'), { preserveScroll: true });
};

const submitProfile = () => {
    formProfile.patch(route('profile.update'), { preserveScroll: true });
};
</script>

<template>
    <AppLayout :breadcrumbs="breadcrumbs">
        <Head title="Profile settings" />

        <SettingsLayout>
            <div class="flex flex-col space-y-10">
                <!-- User Information Form -->
                <div>
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
                    </form>
                </div>

                <!-- Profile Form -->
                <div>
                    <HeadingSmall title="Profile Details" description="Manage additional profile information" />
                    <form @submit.prevent="submitProfile" class="space-y-6">
                        <div class="grid gap-2">
                            <Label for="timezone">Timezone</Label>
                            <Input id="timezone" v-model="formProfile.timezone" />
                            <InputError class="mt-2" :message="formProfile.errors.timezone" />
                        </div>

                        <div class="grid gap-2">
                            <Label for="bio">Bio</Label>
                            <Input id="bio" v-model="formProfile.bio" />
                            <InputError class="mt-2" :message="formProfile.errors.bio" />
                        </div>

                        <div class="grid gap-2">
                            <Label for="x_link">Twitter/X</Label>
                            <Input id="x_link" v-model="formProfile.x_link" />
                            <InputError class="mt-2" :message="formProfile.errors.x_link" />
                        </div>

                        <!-- Add other social inputs here similarly -->

                        <div class="flex items-center gap-4">
                            <Button :disabled="formProfile.processing">Save Profile</Button>
                            <p v-show="formProfile.recentlySuccessful" class="text-sm text-neutral-600">Saved.</p>
                        </div>
                    </form>
                </div>

                <DeleteUser />
            </div>
        </SettingsLayout>
    </AppLayout>
</template>
