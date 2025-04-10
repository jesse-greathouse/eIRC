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
