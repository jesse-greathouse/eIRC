// File: PrivmsgHandler.hpp
// Requires: C++23
// Purpose: Defines a handler for PRIVMSG events, logging incoming private messages
//          to the IRC client’s logger for inspection or debugging.

#pragma once

#include "../IRCClient.hpp"
#include <functional>
#include <string>

inline std::function<void(IRCClient &, const std::string &)> privmsgHandler()
{
	return [](IRCClient &client, const std::string &line)
	{
		client.getLogger().log("[PRIVMSG] " + line + "\n");
	};
}
