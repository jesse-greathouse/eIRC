// File: UsersCommand.hpp
// Requires: C++23
// Purpose: Defines the `/users` command, which outputs the list of users in a given IRC channel.
//          Utilizes IRCClient's channel state to format and display the user list via the UI adapter.

#pragma once

#include "Command.hpp"
#include "../IRCClient.hpp"

inline Command UsersCommand{
	[](const std::string &input)
	{
		return input.rfind("/users ", 0) == 0;
	},
	[](IRCClient &client, const std::string &input)
	{
		std::string channel = input.substr(7);
		client.getUi().drawOutput(client.formatUserList(channel));
	}};
