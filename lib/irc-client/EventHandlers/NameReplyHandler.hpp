// File: NameReplyHandler.hpp
// Requires: C++23
// Purpose: Defines a handler for RPL_NAMEREPLY events. Invokes IRCClient::handleNameReply
//          to parse and update channel user lists when a NAMES response is received.

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
