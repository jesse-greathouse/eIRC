// File: main.cpp
// Requires: C++23
// Purpose: Entry point for the IRC client. Parses arguments, sets up I/O abstraction,
//          initializes the client, registers event handlers, and manages execution flow
//          using modern memory and container features of C++23.

#include "IRCClient.hpp"
#include "IRCEventKeys.hpp"
#include "AuthStrategy.hpp"
#include "SaslAdapter.hpp"
#include "NickServAdapter.hpp"
#include "NcursesUI.hpp"
#include "UnixSocketUI.hpp"
#include "Logger.hpp"
#include "ArgParser.hpp"
#include "IOAdapter.hpp"

#include <iostream>
#include <asio.hpp>
#include <memory>

// Event Handlers
#include "EventHandlers/MotdEndHandler.hpp"
#include "EventHandlers/NameReplyHandler.hpp"
#include "EventHandlers/PingHandler.hpp"
#include "EventHandlers/WhoisHandler.hpp"

// Add new handlers here:
// return {
//     {IRCEventKey::PrivMsg, {
//          channelMsgHandler(),
//          userToUserMsgHandler(),
//      }},
//     {IRCEventKey::Notice, {
//          noticeHandler(),
//      }},
//     {IRCEventKey::MotdEnd, {motdEndHandler()}},
//     {IRCEventKey::RplNameReply, {nameReplyHandler()}},
//     {IRCEventKey::Ping, {pingHandler()}},
//     {IRCEventKey::Whois, {whoisHandler()}},
// };

std::map<std::string, std::vector<std::function<void(IRCClient &, const std::string &)>>> buildHandlers()
{
    return {
        {IRCEventKey::MotdEnd, {motdEndHandler()}},
        {IRCEventKey::RplNameReply, {nameReplyHandler()}},
        {IRCEventKey::Ping, {pingHandler()}},
        {IRCEventKey::Whois, {whoisHandler()}},
    };
}

int main(int argc, char *argv[])
{
    try
    {
        ArgParser parser(argc, argv);
        ParsedArgs args = parser.getArgs();
        Logger logger(args.logPath);
        std::string instance_id = args.instance;

        std::unique_ptr<IOAdapter> io;
        if (!args.listenSocket.empty())
        {
            io = std::make_unique<UnixSocketUI>(args.listenSocket, logger);
        }
        else
        {
            io = std::make_unique<NcursesUI>();
        }

        io->init();
        logger.log("Starting IRC client...");

        asio::io_context ioContext;
        IRCClient client(ioContext, logger, *io, args.channels);

        // Register event handlers
        for (const auto &[event, handlers] : buildHandlers())
        {
            for (const auto &handler : handlers)
            {
                client.addEventHandler(event, handler);
            }
        }

        // Start client connection
        client.connect(args.server, args.port);

        // 1) Choose adapter
        std::unique_ptr<AuthStrategy> auth;
        if (args.useSasl)
        {
            // Pass the realname (unique user key) plus the password
            auth = std::make_unique<SaslAdapter>(
                args.realname,
                args.password);
        }
        else
        {
            auth = std::make_unique<NickServAdapter>(
                args.password);
        }

        // 2) Run negotiation
        auth->negotiate(client);

        // 3) Proceed with the normal NICK/USER
        client.authenticate(args.nick, args.user, args.realname);

        // Start background input thread (now joinable)
        client.startInputLoop();

        // Blocking read loop on main thread
        client.readLoop(args.channels);

        // Wait for the input thread to finish
        client.joinInputLoop(); // <-- NEW: ensures exception in input thread is handled

        io->shutdown();
    }
    catch (const std::exception &e)
    {
        std::cerr << "Exception: " << e.what() << std::endl;
        return 1; // exit with error
    }

    return 0;
}
