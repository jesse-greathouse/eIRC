// File: IRCClient.hpp
// Requires: C++23
// Purpose: Declares the IRCClient class, which manages the lifecycle of an IRC session,
//          including connection, authentication, input/output loops, command execution,
//          event handling, and channel/user state. Central class in the client architecture.

#pragma once

#include <utility>
#include <asio.hpp>
#include <asio/ssl.hpp>

#include <atomic>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <thread>
#include <vector>
#include <stdexcept>

#include "Channel.hpp"
#include "Commands/Command.hpp"
#include "EventHandler.hpp"
#include "IOAdapter.hpp"
#include "Logger.hpp"
#include "User.hpp"


class IRCClient
{
public:
	using tcp_socket = asio::ip::tcp::socket;
	using ssl_stream = asio::ssl::stream<tcp_socket>;

	IRCClient(asio::io_context &context, Logger &logger, IOAdapter &ui, const std::vector<std::string> &channels);

	~IRCClient();

	/**
	 * Establish a connection to `server:port`.
	 * If port==6697, performs a TLS handshake (may throw std::runtime_error on failure).
	 */
	void connect(const std::string &server, int port);
	void authenticate(const std::string &nick, const std::string &user, const std::string &realname);
	void startInputLoop();
	void readLoop(const std::vector<std::string> &channels);
	void joinInputLoop();
	void stop();
	void signoff(const std::map<std::string, Channel> &channels, const std::string &quitMessage);
	void writeToServer(const std::string &message);

	void joinChannels(const std::vector<std::string> &channels);

	void addEventHandler(const std::string &eventKey, std::function<void(IRCClient &, const std::string &)> handler);

	[[nodiscard]] bool isChannelsJoined() const noexcept;
	void setChannelsJoined(bool value);

	[[nodiscard]] std::string formatUserList(const std::string &channelName) const;
	[[nodiscard]] std::string formatChannelList() const;

	[[nodiscard]] const std::vector<std::string> &getJoinedChannels() const;
	[[nodiscard]] const std::map<std::string, User> &getUsers() const;
	[[nodiscard]] const std::map<std::string, Channel> &getChannels() const;

	User *findOrCreateUser(const std::string &nick);

	Logger &getLogger();
	IOAdapter &getUi();

	// Public for use in event handlers
	void handlePing(const std::string &message);
	void handleNameReply(const std::string &rawLine);

	template <typename T>
	T &getSocket();

private:
	void registerEventHandlers();
	void registerCommands();
	void sanitizeInput(std::string &input);

	std::size_t readFromServer(char *data, std::size_t size);

	template <typename SocketType>
	void writeToSocket(SocketType &socket, const std::string &message);

	asio::io_context &ioContext;
	Logger &logger;
	IOAdapter &ui;

	std::function<void(const std::string &)> socketWriter;
	std::unique_ptr<asio::ip::tcp::socket> plainSocket;
	std::unique_ptr<asio::ssl::stream<asio::ip::tcp::socket>> sslSocket;
	std::optional<asio::ssl::context> sslContext;

	bool useTls = false;
	std::atomic<bool> channelsJoined = false;
	std::atomic<bool> running = true;

	std::map<std::string, User> users;
	std::map<std::string, Channel> channels;
	std::map<std::string, EventHandler> eventHandlers;
	std::vector<Command> commands;
	std::vector<std::string> joinedChannels;

	std::thread inputThread;
};
