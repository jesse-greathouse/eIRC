// EventHandlers/PingHandler.hpp
#pragma once

#include "../Logger.hpp"
#include <functional>
#include <string>

inline std::function<void(const std::string &)> pingHandler(Logger &logger)
{
	return [&logger](const std::string &line)
	{
		logger.log("[PING] " + line + "\n");
	};
}
