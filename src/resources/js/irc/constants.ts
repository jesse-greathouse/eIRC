export const IRC_EVENT_KEYS = {
    PING: 'PING',
    PRIVMSG: 'PRIVMSG',
    JOIN: 'JOIN',
    PART: 'PART',
    QUIT: 'QUIT',
    KICK: 'KICK',
    NICK: 'NICK',
    TOPIC: 'TOPIC',
    MODE: 'MODE',
    WELCOME: '001',

    // RPL replies
    RPL_NAMEREPLY: '353',
    RPL_ENDOFNAMES: '366',
    RPL_TOPIC: '332',
    RPL_TOPICWHOTIME: '333',

    // WHOIS replies
    RPL_WHOISAWAY: '301',
    RPL_WHOISUSER: '311',
    RPL_WHOISSERVER: '312',
    RPL_WHOISOPERATOR: '313',
    RPL_WHOISIDLE: '317',
    RPL_ENDOFWHOIS: '318',
    RPL_WHOISCHANNELS: '319',

    // MOTD replies
    MOTD_START: '375',
    MOTD_LINE: '372',
    MOTD_END: '376',
};
