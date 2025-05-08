// File: ArgParser.hpp
// Requires: C++23
// Purpose: Declares the ArgParser class and ParsedArgs struct used to parse and store
//          command-line arguments for configuring the IRC client, including network parameters,
//          logging, channels, and instance identification.

#pragma once

#include <string>
#include <map>
#include <set>
#include <vector>
#include <filesystem> // Required for computing logPath

struct ParsedArgs
{
    std::string nick;
    std::string user;     // <-- will mirror realname
    std::string realname; // <-- received from CLI or API
    std::string server;
    int port;
    std::vector<std::string> channels;
    std::string logPath;
    std::string listenSocket;
    std::string instance;
    bool useSasl = false; // set by --sasl
};

class ArgParser
{
public:
	ArgParser(int argc, char *argv[]);
	ParsedArgs getArgs() const;

private:
	ParsedArgs parsed;

    // helper data structures
    std::vector<std::string> tokens;              // raw argv strings
    std::map<std::string, std::string> keyValues; // --key=value
    std::set<std::string> flags;                  // bare --flag

    // helper init methods
    void tokenize(int argc, char *argv[]);
    void splitKeyValuesAndFlags();
    void applyUserAndRealnameDefaults();

    std::string makeInstanceId() const;
	std::string makeLogPath(const std::string &instance, const std::string &logDir) const;
	std::string makeSocketPath(const std::string &instance, const std::string &listenDir) const;
};
