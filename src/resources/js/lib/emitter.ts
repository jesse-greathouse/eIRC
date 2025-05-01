import mitt from 'mitt';

type Events = {
    'switch-tab': string;
    'joined-channel': string;
    'new-privmsg': string;
    'close-all-popovers': void;
    'mode-change': { nick: string; channel: string; mode: string };
};

const emitter = mitt<Events>();

export default emitter;
