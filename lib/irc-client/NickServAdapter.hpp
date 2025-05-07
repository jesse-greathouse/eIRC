#pragma once
#include "AuthStrategy.hpp"
#include <string>

struct NickServAdapter final : AuthStrategy
{
	explicit NickServAdapter(std::string pass)
		: pass_(std::move(pass)) {}

	void negotiate(IRCClient &client) override;

private:
	std::string pass_;
};
