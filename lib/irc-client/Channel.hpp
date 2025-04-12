// File: Channel.hpp
// Requires: C++23
// Purpose: Defines the Channel struct, representing an IRC channel with a name and a list of
//          associated users. Used to manage channel membership and state within the IRC client.

#pragma once

#include <string>
#include <vector>
#include "User.hpp"

struct Channel
{
	std::string name;
	std::vector<User *> users;
};
