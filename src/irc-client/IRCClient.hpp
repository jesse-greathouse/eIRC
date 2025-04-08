#pragma once

#include <string>
#include <map>
#include <vector>
#include <asio.hpp>
#include "Logger.hpp"
#include "IOAdapter.hpp"

struct User
{
	std::string nick;
	std::string status; // "", "@", or "+"
};

struct EventHandler
{
	std::function<bool(const std::string &)> predicate;
	std::vector<std::function<void(const std::string &)>> handlers;
};

class IRCClient
{
public:
	IRCClient(asio::io_context &, Logger &, IOAdapter &, const std::vector<std::string> &channels);

	void connect(const std::string &server, int port);
	void authenticate(const std::string &nick, const std::string &user);
	void startInputLoop();
	void readLoop(const std::vector<std::string> &channels);
	void signoff(const std::vector<std::string> &channels, const std::string &quitMessage);
	void addEventHandler(const std::string &eventKey, std::function<void(const std::string &)> handler);

private:
	void registerEventHandlers();
	void handlePing(const std::string &message);
	void handleRplNameReply(const std::string &rawLine);
	void joinChannels(const std::vector<std::string> &channels);
	std::string formatUserList(const std::string &channelName) const;
	std::string formatChannelList() const;

	std::map<std::string, EventHandler> eventHandlers;
	std::map<std::string, std::vector<User>> channels;
	asio::io_context &ioContext;
	asio::ip::tcp::socket socket;
	Logger &logger;
	IOAdapter &ui;
	std::atomic<bool> joined;
	std::vector<std::string> joinedChannels; // Stores parsed channel names from ArgParser
};
