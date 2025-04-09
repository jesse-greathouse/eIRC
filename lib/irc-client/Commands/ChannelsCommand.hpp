#pragma once

#include "Command.hpp"
#include "../IRCClient.hpp"

inline Command ChannelsCommand{
	[](const std::string &input)
	{
		return input == "/channels" || input.rfind("/channels ", 0) == 0;
	},
	[](IRCClient &client, const std::string &input)
	{
		client.getUi().drawOutput(client.formatChannelList());
	}};
