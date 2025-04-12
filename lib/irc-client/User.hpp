// File: User.hpp
// Requires: C++23
// Purpose: Defines the User struct representing an IRC user, including nickname, status prefix
//          (e.g., operator or voiced), and optional WHOIS metadata via WhoisState.

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
