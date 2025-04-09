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
