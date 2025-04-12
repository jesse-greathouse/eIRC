// File: ArgParser.hpp
// Requires: C++23
// Purpose: Declares the ArgParser class and ParsedArgs struct used to parse and store
//          command-line arguments for configuring the IRC client, including network parameters,
//          logging, channels, and instance identification.

#pragma once

#include <string>
#include <map>
#include <vector>
#include <filesystem> // Required for computing logPath

struct ParsedArgs
{
	std::string nick;
	std::string user;
	std::string server;
	int port;
	std::vector<std::string> channels;
	std::string logPath;
	std::string listenSocket;
	std::string instance;
};

class ArgParser
{
public:
	ArgParser(int argc, char *argv[]);
	ParsedArgs getArgs() const;

private:
	ParsedArgs parsed;
	std::string makeInstanceId() const;

	std::string makeLogPath(const std::string &instance, const std::string &logDir) const;
	std::string makeSocketPath(const std::string &instance, const std::string &listenDir) const;
};
