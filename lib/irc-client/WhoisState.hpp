// File: WhoisState.hpp
// Requires: C++23
// Purpose: Defines the WhoisState struct, which stores detailed metadata about an IRC user obtained
//          from WHOIS responses, including real name, server info, channel list, idle time, and sign-on time.

#pragma once

#include <string>

struct WhoisState
{
	std::string realname;
	std::string server;
	std::string serverInfo;
	std::string channels;
	std::string idleSeconds;
	std::string signonTime;
};
