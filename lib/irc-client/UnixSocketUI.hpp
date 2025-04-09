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
