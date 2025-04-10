#pragma once

#include <string>
#include <vector>
#include "User.hpp"

struct Channel
{
	std::string name;
	std::vector<User *> users;
};
