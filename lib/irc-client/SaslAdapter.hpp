#pragma once
#include "AuthStrategy.hpp"
#include <string>

struct SaslAdapter final : AuthStrategy
{
	// Now takes both user and pass
	SaslAdapter(std::string user, std::string pass)
		: user_(std::move(user)), pass_(std::move(pass)) {}

	void negotiate(IRCClient &client) override;

private:
	std::string user_;
	std::string pass_;
};
