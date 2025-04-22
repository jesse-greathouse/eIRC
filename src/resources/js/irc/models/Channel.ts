import type { User } from './User';

export class Channel {
    name: string;
    topic: string;
    users: Set<User>;
    ops: Set<User>;
    voice: Set<User>;

    constructor(name: string, topic: string = '') {
        this.name = name;
        this.topic = topic;
        this.users = new Set<User>();
        this.ops = new Set<User>();
        this.voice = new Set<User>();
    }

    addUser(user: User) {
        this.users.add(user);
    }

    removeUser(user: User) {
        this.users.delete(user);
        this.ops.delete(user);
        this.voice.delete(user);
    }

    setTopic(topic: string) {
        this.topic = topic;
    }

    serialize(): object {
        return {
            name: this.name,
            topic: this.topic,
            users: Array.from(this.users).map(user => user.nick),
            ops: Array.from(this.ops).map(user => user.nick),
            voice: Array.from(this.voice).map(user => user.nick),
        };
    }

    toJson(pretty: boolean = false): string {
        return JSON.stringify(this.serialize(), null, pretty ? 2 : 0);
    }
}
