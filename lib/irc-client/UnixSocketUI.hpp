// File: UnixSocketUI.hpp
// Requires: C++23
// Purpose: Declares the UnixSocketUI class, an implementation of the IOAdapter interface that uses
//          UNIX domain sockets to enable communication between the IRC client and external processes.
//          Provides methods for initialization, shutdown, output rendering, and input retrieval.

#pragma once

#include "IOAdapter.hpp"
#include "Logger.hpp"
#include <string>
#include <sys/socket.h>
#include <sys/un.h>

class UnixSocketUI : public IOAdapter
{
public:
	UnixSocketUI(const std::string &path, Logger &logger);
	~UnixSocketUI();
	void init() override;
	void shutdown() override;
	void drawOutput(const std::string &line) override;
	std::string getInput() override;

private:
	std::string socketPath;
	int serverFd = -1;
	int clientFd = -1;
	Logger &logger;
};
