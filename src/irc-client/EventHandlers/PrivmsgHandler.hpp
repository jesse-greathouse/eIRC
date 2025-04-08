// EventHandlers/PrivmsgHandler.hpp
#pragma once

#include "../Logger.hpp"
#include <functional>
#include <string>

inline std::function<void(const std::string &)> privmsgHandler(Logger &logger)
{
	return [&logger](const std::string &line)
	{
		logger.log("[PRIVMSG] " + line + "\n");
	};
}
