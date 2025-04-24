// File: ArgParser.cpp
// Requires: C++23
// Purpose: Parses command-line arguments into structured configuration for the IRC client,
//          including support for instance ID generation using modern random utilities.

#include "ArgParser.hpp"
#include <sstream>
#include <random>
#include <iomanip>
#include <filesystem>

namespace fs = std::filesystem;

ArgParser::ArgParser(int argc, char *argv[])
{
	std::map<std::string, std::string> args;
	for (int i = 1; i < argc; ++i)
	{
		std::string arg(argv[i]);
		auto eq = arg.find('=');
		if (arg.rfind("--", 0) == 0 && eq != std::string::npos)
		{
			args[arg.substr(2, eq - 2)] = arg.substr(eq + 1);
		}
	}
	applyUserAndRealnameDefaults(args);

	parsed.server = args["server"];
	parsed.port = std::stoi(args["port"]);
	parsed.instance = (args.count("instance") && !args["instance"].empty()) ? args["instance"] : makeInstanceId();
	parsed.listenSocket = makeSocketPath(parsed.instance, args.count("listen") ? args["listen"] : "");
	parsed.logPath = makeLogPath(parsed.instance, args.count("log") ? args["log"] : "");

	std::stringstream ss(args["channels"]);
	std::string channel;
	while (std::getline(ss, channel, ','))
	{
		parsed.channels.push_back(channel);
	}
}

ParsedArgs ArgParser::getArgs() const
{
	return parsed;
}

std::string ArgParser::makeInstanceId() const
{
	std::random_device rd;
	std::mt19937 gen(rd());
	std::uniform_int_distribution<> dis(0, 255);

	std::ostringstream oss;
	for (int i = 0; i < 16; ++i)
	{
		oss << std::hex << std::setw(2) << std::setfill('0') << dis(gen);
	}
	return oss.str();
}

std::string ArgParser::makeLogPath(const std::string &instance, const std::string &logDir) const
{
	std::string logFileName = "irc-client-" + instance + ".log";

	if (!logDir.empty())
	{
		return (std::filesystem::path(logDir) / logFileName).string();
	}
	else
	{
		return (std::filesystem::current_path() / logFileName).string();
	}
}

std::string ArgParser::makeSocketPath(const std::string &instance, const std::string &listenDir) const
{
	std::string socketFile = "irc-client-" + instance + ".sock";

	if (!listenDir.empty())
	{
		return (std::filesystem::path(listenDir) / socketFile).string();
	}
	else
	{
		return (std::filesystem::current_path() / socketFile).string();
	}
}

void ArgParser::applyUserAndRealnameDefaults(const std::map<std::string, std::string> &args)
{
	auto nickIt = args.find("nick");
	if (nickIt == args.end() || nickIt->second.empty())
	{
		throw std::invalid_argument("Missing required argument: --nick");
	}

	parsed.nick = nickIt->second;

	auto realnameIt = args.find("realname");
	parsed.realname = (realnameIt != args.end() && !realnameIt->second.empty()) ? realnameIt->second : parsed.nick;

	parsed.user = parsed.realname; // Keep user = realname
}
