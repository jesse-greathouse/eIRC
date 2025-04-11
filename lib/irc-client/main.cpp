#include "IRCClient.hpp"
#include "NcursesUI.hpp"
#include "UnixSocketUI.hpp"
#include "Logger.hpp"
#include "ArgParser.hpp"
#include "IOAdapter.hpp"

#include <iostream>
#include <asio.hpp>
#include <memory>

// Commands
#include "Commands/InputCommand.hpp"

// Event Handlers
#include "EventHandlers/MotdEndHandler.hpp"
#include "EventHandlers/NameReplyHandler.hpp"
#include "EventHandlers/PingHandler.hpp"
#include "EventHandlers/WhoisHandler.hpp"

std::map<std::string, std::vector<std::function<void(IRCClient &, const std::string &)>>> buildHandlers()
{
    return {
        {"MOTD_END", {motdEndHandler()}},
        {"RPL_NAMEREPLY", {nameReplyHandler()}},
        {"PING", {pingHandler()}},
        {"WHOIS", {whoisHandler()}},
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
        client.authenticate(args.nick, args.user);

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
