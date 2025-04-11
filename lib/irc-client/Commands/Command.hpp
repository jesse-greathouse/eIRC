#pragma once

#include <string>
#include <functional>

class IRCClient; // Forward declaration

struct Command
{
	std::function<bool(const std::string &)> predicate;
	std::function<void(IRCClient &, const std::string &)> handler;
};
