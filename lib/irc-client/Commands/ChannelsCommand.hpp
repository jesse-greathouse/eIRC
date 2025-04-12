// File: ChannelsCommand.hpp
// Requires: C++23
// Purpose: Defines the `/channels` command, which outputs a list of all channels the IRC client
//          is currently tracking. Useful for confirming active channel state from the client.

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
