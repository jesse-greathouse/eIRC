#pragma once
#include "AuthStrategy.hpp"
#include <string>

struct SaslAdapter final : AuthStrategy
{
	// no fields—this adapter only drives CAP and signals back to the UI
	SaslAdapter() = default;
	void negotiate(IRCClient &client) override;
};
