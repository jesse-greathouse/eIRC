// File: PingHandler.hpp
// Requires: C++23
// Purpose: Defines a handler for PING events. Delegates to IRCClient::handlePing to respond
//          to server PING messages and maintain connection liveliness.

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
