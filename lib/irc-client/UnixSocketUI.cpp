// File: UnixSocketUI.cpp
// Requires: C++23
// Purpose: Implements a UNIX domain socket-based UI adapter for headless I/O. Accepts connections
//          from an external client, facilitating bidirectional communication between the IRC client
//          and a socket peer (e.g. a WebSocket server or monitoring tool).

#include "UnixSocketUI.hpp"
#include "Logger.hpp"
#include <unistd.h>
#include <cstring>
#include <iostream>

UnixSocketUI::UnixSocketUI(const std::string &path, Logger &logger)
	: socketPath(path), logger(logger) {}

void UnixSocketUI::init()
{
	serverFd = socket(AF_UNIX, SOCK_STREAM, 0);
	if (serverFd < 0)
	{
		perror("socket");
		return;
	}

	sockaddr_un addr{};
	addr.sun_family = AF_UNIX;
	std::strncpy(addr.sun_path, socketPath.c_str(), sizeof(addr.sun_path) - 1);
	unlink(socketPath.c_str());

	if (bind(serverFd, (sockaddr *)&addr, sizeof(addr)) == -1)
	{
		perror("bind");
		return;
	}

	if (listen(serverFd, 1) == -1)
	{
		perror("listen");
		return;
	}

	std::string waitMsg = "Waiting for socket client: " + socketPath;
	logger.log(waitMsg);

	clientFd = accept(serverFd, nullptr, nullptr);
	if (clientFd < 0)
	{
		perror("accept");
	}
	else
	{
		std::string msg = "Client connected to socket: " + socketPath;
		logger.log(msg);
	}
}

void UnixSocketUI::shutdown()
{
	if (clientFd >= 0)
		close(clientFd);
	if (serverFd >= 0)
		close(serverFd);
	unlink(socketPath.c_str());
}

void UnixSocketUI::drawOutput(const std::string &line)
{
	if (clientFd >= 0)
	{
		send(clientFd, line.c_str(), line.length(), 0);
		send(clientFd, "\n", 1, 0);
	}
}

std::string UnixSocketUI::getInput()
{
	char buf[512] = {0};
	if (clientFd >= 0)
	{
		ssize_t len = recv(clientFd, buf, sizeof(buf) - 1, 0);
		if (len > 0)
		{
			return std::string(buf, len);
		}
		else if (len == 0)
		{
			// Connection closed by client
			return ""; // Let the caller decide what to do
		}
	}
	return "";
}
