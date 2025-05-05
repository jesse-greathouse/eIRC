// File: InputCommand.hpp
// Requires: C++23
// Purpose: Defines the `/input` command, which allows raw IRC protocol messages to be sent directly
//          to the server. Useful for advanced usage or debugging unhandled commands.

#pragma once

#include "Command.hpp"
#include "../IRCClient.hpp"
#include <asio.hpp>

inline Command InputCommand{
	// Matches if the input starts with "/input "
	[](const std::string &input)
	{
		return input.rfind("/input ", 0) == 0;
	},
	// Sends the remainder of the message to the IRC server
	[](IRCClient &client, const std::string &input)
	{
		std::string raw = input.substr(7); // strip "/input "
		std::string message = raw + "\n";
		client.sendRaw(message);
		client.getLogger().log("→ " + raw);
	}};
