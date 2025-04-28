import mitt from 'mitt';

type Events = {
    'switch-tab': string;
    'joined-channel': string;
    'new-privmsg': string;
    'close-all-popovers': void;
};

const emitter = mitt<Events>();

export default emitter;
