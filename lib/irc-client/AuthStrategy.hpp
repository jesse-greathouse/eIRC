#pragma once
#include "IRCClient.hpp"

// Pluggable auth strategy interface
struct AuthStrategy
{
	virtual ~AuthStrategy() = default;
	// Perform whatever handshake is needed before NICK/USER
	virtual void negotiate(IRCClient &client) = 0;
};
