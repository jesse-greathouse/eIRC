// File: QuitCommand.hpp
// Requires: C++23
// Purpose: Defines the `/quit` command, which logs a disconnect request and gracefully signs off
//          from all joined channels using the IRCClient's signoff mechanism.

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
		client.signoff(client.getChannels(), "eIRC ( https://github.com/jesse-greathouse/eIRC )");
	}};
