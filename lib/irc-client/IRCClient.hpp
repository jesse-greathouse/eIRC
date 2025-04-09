#pragma once

#include <string>
#include <map>
#include <optional>
#include <vector>
#include <asio.hpp>
#include <atomic>
#include "Logger.hpp"
#include "IOAdapter.hpp"
#include "Commands/Command.hpp"

class IRCClient;

struct WhoisState
{
	std::string realname;
	std::string server;
	std::string serverInfo;
	std::string channels;
	std::string idleSeconds;
	std::string signonTime;
};

struct User
{
	std::string nick;
	std::string status; // "", "@", "+"
	std::optional<WhoisState> whoisState;
};

struct Channel
{
	std::string name;
	std::vector<User *> users;
};

struct EventHandler
{
	std::function<bool(const std::string &)> predicate;
	std::vector<std::function<void(IRCClient &, const std::string &)>> handlers;
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
