// File: WhoisHandler.hpp
// Requires: C++23
// Purpose: Provides inline WHOIS response handlers for various IRC numeric codes (311–319).
//          Dispatches parsed user metadata into the IRCClient's internal user map and logs
//          a formatted WHOIS summary once complete.

#pragma once

#include "../IRCClient.hpp"
#include <functional>
#include <string>

inline void handle311(IRCClient &, const std::string &);
inline void handle312(IRCClient &, const std::string &);
inline void handle317(IRCClient &, const std::string &);
inline void handle318(IRCClient &, const std::string &);
inline void handle319(IRCClient &, const std::string &);

// Main WHOIS dispatcher
inline std::function<void(IRCClient &, const std::string &)> whoisHandler()
{
	return [](IRCClient &client, const std::string &line) -> void
	{
		if (line.find(" 311 ") != std::string::npos)
			return handle311(client, line);
		if (line.find(" 312 ") != std::string::npos)
			return handle312(client, line);
		if (line.find(" 317 ") != std::string::npos)
			return handle317(client, line);
		if (line.find(" 318 ") != std::string::npos)
			return handle318(client, line);
		if (line.find(" 319 ") != std::string::npos)
			return handle319(client, line);
		if (line.find(" 301 ") != std::string::npos)
			return handle301(client, line);
		if (line.find(" 313 ") != std::string::npos)
			return handle313(client, line);
	};
}

// Helper: find or create user
User *findOrCreateUser(IRCClient &client, const std::string &nick)
{
	auto &users = client.getUsers();
	auto it = users.find(nick);
	if (it != users.end())
		return const_cast<User *>(&it->second);

	// Add to user map if not found
	auto &userMap = const_cast<std::map<std::string, User> &>(users);
	auto [newIt, _] = userMap.emplace(nick, User{nick, "", std::nullopt});
	return &newIt->second;
}

// WHOIS 311
inline void handle311(IRCClient &client, const std::string &line)
{
	std::istringstream iss(line);
	std::string prefix, code, target, nick, user, host, star;
	std::string realname;
	iss >> prefix >> code >> target >> nick >> user >> host >> star;
	std::getline(iss, realname);
	realname = realname.substr(2); // strip " :"

	User *u = findOrCreateUser(client, nick);
	if (!u->whoisState)
		u->whoisState.emplace();
	u->whoisState->username = user; // Save ident/username
	u->whoisState->host = host;		// Save host separately
	u->whoisState->realname = realname;
}

// WHOIS 312
inline void handle312(IRCClient &client, const std::string &line)
{
	std::istringstream iss(line);
	std::string prefix, code, target, nick, server, serverInfo;
	iss >> prefix >> code >> target >> nick >> server;
	std::getline(iss, serverInfo);
	serverInfo = serverInfo.substr(2);

	User *u = findOrCreateUser(client, nick);
	if (!u->whoisState)
		u->whoisState.emplace();
	u->whoisState->server = server;
	u->whoisState->serverInfo = serverInfo;
}

// WHOIS 317
inline void handle317(IRCClient &client, const std::string &line)
{
	std::istringstream iss(line);
	std::string prefix, code, target, nick, idle, signon;
	iss >> prefix >> code >> target >> nick >> idle >> signon;

	User *u = findOrCreateUser(client, nick);
	if (!u->whoisState)
		u->whoisState.emplace();
	u->whoisState->idleSeconds = idle;
	u->whoisState->signonTime = signon;
}

// WHOIS 319
inline void handle319(IRCClient &client, const std::string &line)
{
	std::istringstream iss(line);
	std::string prefix, code, target, nick;
	iss >> prefix >> code >> target >> nick;

	std::string remainder;
	std::getline(iss, remainder);
	remainder = remainder.substr(2); // strip " :"

	User *u = findOrCreateUser(client, nick);
	if (!u->whoisState)
		u->whoisState.emplace();
	u->whoisState->channels = remainder;
}

// WHOIS 318 (final step)
inline void handle318(IRCClient &client, const std::string &line)
{
	std::istringstream iss(line);
	std::string prefix, code, target, nick;
	iss >> prefix >> code >> target >> nick;

	User *u = findOrCreateUser(client, nick);
	if (!u || !u->whoisState)
		return;

	// const WhoisState &ws = *u->whoisState;
	// std::stringstream out;
	// out << "WHOIS: " << u->nick << "\n"
	// 	<< "  Real Name: " << ws.realname << "\n"
	// 	<< "  Server: " << ws.server << " (" << ws.serverInfo << ")\n"
	// 	<< "  Channels: " << ws.channels << "\n"
	// 	<< "  Idle: " << ws.idleSeconds << "s, Signon: " << ws.signonTime;

	// client.getLogger().log(out.str());
	// client.getUi().drawOutput(out.str());

	// Optionally clear WHOIS info
	// u->whoisState.reset();
}

inline void handle301(IRCClient &client, const std::string &line)
{
	std::istringstream iss(line);
	std::string prefix, code, target, nick;
	iss >> prefix >> code >> target >> nick;

	std::string awayMsg;
	std::getline(iss, awayMsg);
	awayMsg = awayMsg.substr(2);

	User *u = findOrCreateUser(client, nick);
	if (!u->whoisState)
		u->whoisState.emplace();
	u->whoisState->awayMessage = awayMsg;
}

inline void handle313(IRCClient &client, const std::string &line)
{
	std::istringstream iss(line);
	std::string prefix, code, target, nick;
	iss >> prefix >> code >> target >> nick;

	User *u = findOrCreateUser(client, nick);
	if (!u->whoisState)
		u->whoisState.emplace();
	u->whoisState->isOperator = true;
}
