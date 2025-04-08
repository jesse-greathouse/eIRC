#pragma once

#include <string>
#include <map>
#include <vector>

struct ParsedArgs
{
	std::string nick;
	std::string user;
	std::string server;
	int port;
	std::vector<std::string> channels;
	std::string logPath;
	std::string listenSocket;
};

class ArgParser
{
public:
	ArgParser(int argc, char *argv[]);
	ParsedArgs getArgs() const;

private:
	ParsedArgs parsed;
};
