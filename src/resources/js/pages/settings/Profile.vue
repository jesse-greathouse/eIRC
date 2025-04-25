<script setup lang="ts">
import { computed } from 'vue';
import { Head, useForm } from '@inertiajs/vue3';
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar';
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import InputError from '@/components/InputError.vue';
import HeadingSmall from '@/components/HeadingSmall.vue';
import AppLayout from '@/layouts/AppLayout.vue';
import SettingsLayout from '@/layouts/settings/Layout.vue';
import { type BreadcrumbItem, type Profile } from '@/types';

interface Props {
    profile: Profile;
}

const props = defineProps<Props>();

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Profile settings', href: '/settings/profile' },
];

const formProfile = useForm<{
    timezone: string;
    bio: string;
    x_link: string;
    instagram_link: string;
    tiktok_link: string;
    youtube_link: string;
    facebook_link: string;
    pinterest_link: string;
    avatar: File | null;
    selected_avatar_id: number | null;
}>({
    timezone: props.profile.timezone || 'UTC',
    bio: props.profile.bio || '',
    x_link: props.profile.x_link || '',
    instagram_link: props.profile.instagram_link || '',
    tiktok_link: props.profile.tiktok_link || '',
    youtube_link: props.profile.youtube_link || '',
    facebook_link: props.profile.facebook_link || '',
    pinterest_link: props.profile.pinterest_link || '',
    avatar: null,
    selected_avatar_id: props.profile.selected_avatar_id || null,
});

const handleAvatarChange = (event: Event) => {
    const target = event.target as HTMLInputElement;
    if (target.files && target.files.length > 0) {
        formProfile.avatar = target.files[0];
    }
};

const submitProfile = () => {
    formProfile.post(route('profile.update'), {
        preserveScroll: true,
        forceFormData: true,
    });
};

const socialFields = {
    x_link: 'Twitter/X',
    instagram_link: 'Instagram',
    tiktok_link: 'TikTok',
    youtube_link: 'YouTube',
    facebook_link: 'Facebook',
    pinterest_link: 'Pinterest',
};

// Assuming props.profile.selected_avatar?.base64_data could be null
const avatarUrl = computed(() => {
    return props.profile.selected_avatar?.base64_data
        ? props.profile.selected_avatar.base64_data
        : '/avatar-placeholder.png'; // fallback to placeholder
});
</script>

<template>
    <AppLayout :breadcrumbs="breadcrumbs">

        <Head title="Profile settings" />

        <SettingsLayout>
            <div class="flex flex-col space-y-10">
                <HeadingSmall title="Profile Settings" description="Manage your profile appearance and social links" />

                <form @submit.prevent="submitProfile" class="space-y-6" enctype="multipart/form-data">
                    <Card>
                        <CardHeader>
                            <CardTitle>Profile Details</CardTitle>
                        </CardHeader>

                        <CardContent class="grid grid-cols-1 md:grid-cols-3 gap-6">
                            <!-- Avatar Upload and Preview -->
                            <div class="flex flex-col items-center gap-4 md:col-span-1">
                                <Avatar size="lg">
                                    <AvatarImage :src="avatarUrl" />
                                    <AvatarFallback>?</AvatarFallback> <!-- You can customize this -->
                                </Avatar>
                                <div class="w-full">
                                    <Label for="avatar">Upload New Avatar</Label>
                                    <Input id="avatar" type="file" @change="handleAvatarChange" />
                                    <InputError class="mt-2" :message="formProfile.errors.avatar" />
                                </div>
                            </div>

                            <!-- Timezone & Bio Fields -->
                            <div class="md:col-span-2 grid gap-4">
                                <div>
                                    <Label for="timezone">Timezone</Label>
                                    <Input id="timezone" v-model="formProfile.timezone" />
                                    <InputError class="mt-2" :message="formProfile.errors.timezone" />
                                </div>
                                <div>
                                    <Label for="bio">Bio</Label>
                                    <Input id="bio" v-model="formProfile.bio" />
                                    <InputError class="mt-2" :message="formProfile.errors.bio" />
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    <!-- Social Media Links Section -->
                    <Card>
                        <CardHeader>
                            <CardTitle>Social Media Links</CardTitle>
                        </CardHeader>

                        <CardContent class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <template v-for="(label, key) in socialFields" :key="key">
                                <div>
                                    <Label :for="key">{{ label }}</Label>
                                    <Input :id="key" v-model="formProfile[key]" />
                                    <InputError class="mt-2" :message="formProfile.errors[key]" />
                                </div>
                            </template>
                        </CardContent>
                    </Card>

                    <CardFooter class="flex items-center gap-4">
                        <Button :disabled="formProfile.processing">Save Profile</Button>
                        <p v-show="formProfile.recentlySuccessful" class="text-sm text-muted-foreground">Saved.</p>
                    </CardFooter>
                </form>
            </div>
        </SettingsLayout>
    </AppLayout>
</template>
