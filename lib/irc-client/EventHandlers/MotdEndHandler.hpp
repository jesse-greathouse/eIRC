// File: MotdEndHandler.hpp
// Requires: C++23
// Purpose: Defines a handler for MOTD_END events. Triggers automatic channel joins and marks
//          the IRC client as fully connected after the end of the server’s message of the day.

#pragma once

#include "../IRCClient.hpp"
#include <functional>
#include <string>

inline std::function<void(IRCClient &, const std::string &)> motdEndHandler()
{
	return [](IRCClient &client, const std::string &)
	{
		client.joinChannels(client.getJoinedChannels());
		client.setJoined(true);
	};
}
