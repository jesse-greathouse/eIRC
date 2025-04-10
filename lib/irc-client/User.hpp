#pragma once

#include "WhoisState.hpp"
#include <string>
#include <optional>

struct User
{
	std::string nick;
	std::string status; // "", "@", "+"
	std::optional<WhoisState> whoisState;
};
