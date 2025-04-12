// File: IRCClient.hpp
// Requires: C++23
// Purpose: Declares the IRCClient class, which manages the lifecycle of an IRC session,
//          including connection, authentication, input/output loops, command execution,
//          event handling, and channel/user state. Central class in the client architecture.

#pragma once

#include <string>
#include <map>
#include <optional>
#include <vector>
#include <asio.hpp>
#include <atomic>
#include "Channel.hpp"
#include "EventHandler.hpp"
#include "Logger.hpp"
#include "User.hpp"
#include "IOAdapter.hpp"
#include "Commands/Command.hpp"

class IRCClient
{
public:
	IRCClient(asio::io_context &, Logger &, IOAdapter &, const std::vector<std::string> &channels);

	void connect(const std::string &server, int port);
	void authenticate(const std::string &nick, const std::string &user);
	void startInputLoop();
	void readLoop(const std::vector<std::string> &channels);
	void signoff(const std::map<std::string, Channel> &channels, const std::string &quitMessage);
	void addEventHandler(const std::string &eventKey, std::function<void(IRCClient &, const std::string &)> handler);
	void joinChannels(const std::vector<std::string> &channels);
	bool isJoined() const;
	bool getJoined() const;
	void setJoined(bool joined);
	void joinInputLoop();
	void stop();

	std::string formatUserList(const std::string &channelName) const;
	std::string formatChannelList() const;
	const std::vector<std::string> &getJoinedChannels() const;
	asio::ip::tcp::socket &getSocket();
	IOAdapter &getUi();
	User *findOrCreateUser(const std::string &nick);
	const std::map<std::string, User> &getUsers() const;
	const std::map<std::string, Channel> &getChannels() const;

	// Access to Logger and Channels
	Logger &getLogger();

	// Public so event handlers can call this
	void handlePing(const std::string &message);
	void handleNameReply(const std::string &rawLine);

private:
	void registerEventHandlers();
	void registerCommands();
	void sanitizeInput(std::string &input);

	std::map<std::string, EventHandler> eventHandlers;
	std::map<std::string, User> users;
	std::map<std::string, Channel> channels;
	std::vector<Command> commands;
	asio::io_context &ioContext;
	asio::ip::tcp::socket socket;
	Logger &logger;
	IOAdapter &ui;
	std::atomic<bool> joined;
	std::vector<std::string> joinedChannels;
	std::atomic<bool> running{true};
	std::thread inputThread;
};
