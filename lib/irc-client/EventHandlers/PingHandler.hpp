// EventHandlers/PingHandler.hpp
#pragma once

#include "../IRCClient.hpp"
#include <functional>
#include <string>

inline std::function<void(IRCClient &, const std::string &)> pingHandler()
{
	return [](IRCClient &client, const std::string &line)
	{
		client.handlePing(line);
	};
}
