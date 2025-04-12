// File: Command.hpp
// Requires: C++23
// Purpose: Defines the Command struct, which pairs a predicate and a handler function to represent
//          IRC client commands. Used to modularize input command handling within the IRC client.

#pragma once

#include <string>
#include <functional>

class IRCClient; // Forward declaration

struct Command
{
	std::function<bool(const std::string &)> predicate;
	std::function<void(IRCClient &, const std::string &)> handler;
};
