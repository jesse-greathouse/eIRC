#include "IRCClient.hpp"
#include "NcursesUI.hpp"
#include "UnixSocketUI.hpp"
#include "Logger.hpp"
#include "ArgParser.hpp"
#include "IOAdapter.hpp"

#include <iostream>
#include <asio.hpp>
#include <memory>

int main(int argc, char *argv[])
{
    try
    {
        ArgParser parser(argc, argv);
        ParsedArgs args = parser.getArgs();
        Logger logger(args.logPath);

        // Select IO adapter based on presence of --listen
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
        client.connect(args.server, args.port);
        client.authenticate(args.nick, args.user);
        client.startInputLoop();
        client.readLoop(args.channels);

        io->shutdown();
    }
    catch (const std::exception &e)
    {
        std::cerr << "Exception: " << e.what() << std::endl;
    }

    return 0;
}
