#pragma once

struct IRCEventKey
{
	static constexpr const char *Ping = "PING";
	static constexpr const char *RplNameReply = "RPL_NAMEREPLY";
	static constexpr const char *MotdEnd = "MOTD_END";
	static constexpr const char *Privmsg = "PRIVMSG";
	static constexpr const char *Whois = "WHOIS";
};
