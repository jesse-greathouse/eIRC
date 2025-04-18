import type { DefineComponent } from 'vue';

export interface ChatTab {
    id: string;
    label: string;
    component: DefineComponent;
}
