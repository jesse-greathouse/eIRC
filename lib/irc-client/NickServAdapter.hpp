#pragma once
#include "AuthStrategy.hpp"
#include <string>

struct NickServAdapter final : AuthStrategy
{
	NickServAdapter() = default;
	void negotiate(IRCClient &client) override;
};
