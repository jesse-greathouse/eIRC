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
	// Grab argv into vector<string>
	tokenize(argc, argv);

	// Split into keyValues and flags
	splitKeyValuesAndFlags();

	// Use keyValues and flags to fill parsed:
	parsed.useSasl = flags.count("--sasl") > 0;
	parsed.server = keyValues["server"];
	parsed.port = std::stoi(keyValues["port"]);

	// If instance id isnt set, make one
	parsed.instance = (!keyValues["instance"].empty())
						  ? keyValues["instance"]
						  : makeInstanceId();
	// Init socket path
	parsed.listenSocket = makeSocketPath(
		parsed.instance,
		keyValues.count("listen") ? keyValues["listen"] : "");

	// Init log path
	parsed.logPath = makeLogPath(
		parsed.instance,
		keyValues.count("log") ? keyValues["log"] : "");

	// channels
	{
		std::stringstream ss(keyValues["channels"]);
		std::string chan;
		while (std::getline(ss, chan, ','))
		{
			parsed.channels.push_back(chan);
		}
	}

	// finally apply nick/realname defaults
	applyUserAndRealnameDefaults();
}

void ArgParser::tokenize(int argc, char *argv[])
{
	tokens.reserve(argc - 1);
	for (int i = 1; i < argc; ++i)
	{
		tokens.emplace_back(argv[i]);
	}
}

void ArgParser::splitKeyValuesAndFlags()
{
	for (auto &tk : tokens)
	{
		if (!tk.rfind("--", 0))
		{
			auto eq = tk.find('=');
			if (eq != std::string::npos)
			{
				// it's --key=value
				auto key = tk.substr(2, eq - 2);
				auto val = tk.substr(eq + 1);
				keyValues[key] = val;
			}
			else
			{
				// it's a bare flag
				flags.insert(tk);
			}
		}
	}
}

void ArgParser::applyUserAndRealnameDefaults()
{
	// same as before, but pull from keyValues instead of passed map
	auto it = keyValues.find("nick");
	if (it == keyValues.end() || it->second.empty())
	{
		throw std::invalid_argument("Missing required argument: --nick");
	}
	parsed.nick = it->second;

	auto rn = keyValues.find("realname");
	parsed.realname = (rn != keyValues.end() && !rn->second.empty())
						  ? rn->second
						  : parsed.nick;
	parsed.user = parsed.realname;
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
