// File: EventHandler.hpp
// Requires: C++23
// Purpose: Defines the EventHandler struct used to match and process IRC protocol events.
//          Each handler includes a predicate to detect matching lines and a list of
//          callback functions that operate on the IRCClient instance.

#pragma once

#include <string>
#include <vector>
#include <functional>

class IRCClient;

struct EventHandler
{
	std::function<bool(const std::string &)> predicate;
	std::vector<std::function<void(IRCClient &, const std::string &)>> handlers;
};
