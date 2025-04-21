import mitt from 'mitt';

type Events = {
  'switch-tab': string;
  'joined-channel': string;
  'new-privmsg': string;
  // Add more as needed
};

const emitter = mitt<Events>();

export default emitter;
