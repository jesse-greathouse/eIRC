#include "ArgParser.hpp"
#include <sstream>

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
