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
