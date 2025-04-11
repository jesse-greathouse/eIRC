#pragma once

#include "../IRCClient.hpp"
#include <functional>
#include <string>

inline std::function<void(IRCClient &, const std::string &)> nameReplyHandler()
{
	return [](IRCClient &client, const std::string &line)
	{
		client.handleNameReply(line);
	};
}
