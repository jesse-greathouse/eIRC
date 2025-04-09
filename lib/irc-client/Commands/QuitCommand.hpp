#pragma once

#include "Command.hpp"
#include "../IRCClient.hpp"

inline Command QuitCommand{
	[](const std::string &input)
	{
		return input == "/quit";
	},
	[](IRCClient &client, const std::string &input)
	{
		client.getLogger().log("Disconnect requested");
		client.signoff(client.getJoinedChannels(), "eIRC ( https://github.com/jesse-greathouse/eIRC )");
	}};
