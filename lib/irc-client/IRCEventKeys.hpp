// File: IRCEventKeys.hpp
// Requires: C++23
// Purpose: Defines the IRCEventKey struct containing constant string identifiers for IRC protocol events.
//          Used as keys for event handler registration and dispatch in the IRC client.

#pragma once

struct IRCEventKey
{
	static constexpr const char *Ping = "PING";
	static constexpr const char *RplNameReply = "RPL_NAMEREPLY";
	static constexpr const char *MotdEnd = "MOTD_END";
	static constexpr const char *Privmsg = "PRIVMSG";
	static constexpr const char *Whois = "WHOIS";
	static constexpr const char *Cap = "CAP"; // for CAP * LS / ACK
};
