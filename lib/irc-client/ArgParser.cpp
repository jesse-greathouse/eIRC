// File: ArgParser.cpp
// Requires: C++23
// Purpose: Parses command-line arguments into structured configuration for the IRC client,
//          including support for instance ID generation using modern random utilities.

#include "ArgParser.hpp"
#include <sstream>
#include <random>
#include <iomanip>

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

	parsed.nick = args["nick"];
	parsed.user = args["nick"];
	parsed.server = args["server"];
	parsed.port = std::stoi(args["port"]);
	parsed.logPath = args.count("log") ? args["log"] : "client.log";
	parsed.listenSocket = args.count("listen") ? args["listen"] : "";
	parsed.instance = (args.count("instance") && !args["instance"].empty()) ? args["instance"] : makeInstanceId();

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
