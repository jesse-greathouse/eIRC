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
		asio::write(client.getSocket(), asio::buffer(message));
		client.getLogger().log("→ " + raw);
	}};
