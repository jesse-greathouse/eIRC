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
