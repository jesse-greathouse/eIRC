#include "IRCClient.hpp"
#include "IRCEventKeys.hpp"
#include <thread>
#include <sstream>

#include "Commands/QuitCommand.hpp"
#include "Commands/UsersCommand.hpp"
#include "Commands/ChannelsCommand.hpp"
#include "Commands/InputCommand.hpp"

IRCClient::IRCClient(asio::io_context &context, Logger &logger, IOAdapter &ui, const std::vector<std::string> &channels)
    : ioContext(context), socket(context), logger(logger), ui(ui), joined(false), joinedChannels(channels)
{
    std::string joinedList;
    for (const auto &ch : channels)
    {
        if (!joinedList.empty())
            joinedList += ", ";
        joinedList += ch;
    }
    logger.log("IRCClient constructed with channels: " + joinedList);

    registerCommands();
    registerEventHandlers();
}

void IRCClient::registerCommands()
{
    commands = {
        QuitCommand,
        UsersCommand,
        ChannelsCommand,
        InputCommand,
    };
}

void IRCClient::registerEventHandlers()
{
    eventHandlers[IRCEventKey::Ping] = EventHandler{
        [](const std::string &line)
        {
            return line.substr(0, 5) == "PING ";
        },
        {}};

    eventHandlers[IRCEventKey::RplNameReply] = EventHandler{
        [](const std::string &line)
        {
            return line.find(" 353 ") != std::string::npos;
        },
        {}};

    eventHandlers[IRCEventKey::MotdEnd] = EventHandler{
        [this](const std::string &line)
        {
            return !joined && (line.find("376") != std::string::npos || line.find("422") != std::string::npos);
        },
        {}};

    eventHandlers[IRCEventKey::Privmsg] = EventHandler{
        [](const std::string &line)
        {
            return line.find(" PRIVMSG ") != std::string::npos;
        },
        {}};

    eventHandlers[IRCEventKey::Whois] = {
        [](const std::string &line)
        {
            return line.find(" 311 ") != std::string::npos ||
                   line.find(" 312 ") != std::string::npos ||
                   line.find(" 317 ") != std::string::npos ||
                   line.find(" 318 ") != std::string::npos ||
                   line.find(" 319 ") != std::string::npos;
        },
        {}};
}

void IRCClient::connect(const std::string &server, int port)
{
    socket.connect(asio::ip::tcp::endpoint(asio::ip::address::from_string(server), port));
}

void IRCClient::authenticate(const std::string &nick, const std::string &user)
{
    std::string auth = "NICK " + nick + "\nUSER " + user + " 0 * :" + user + "\n";
    asio::write(socket, asio::buffer(auth));
}

void IRCClient::handlePing(const std::string &message)
{
    std::string payload = message.substr(message.find(':') + 1);

    // Trim trailing \r and \n (if any)
    while (!payload.empty() && (payload.back() == '\r' || payload.back() == '\n'))
    {
        payload.pop_back();
    }

    std::string response = "PONG :" + payload + "\n";
    asio::write(socket, asio::buffer(response));
    logger.log("→ " + response.substr(0, response.size() - 1)); // remove final \n for logging
}

void IRCClient::handleNameReply(const std::string &rawLine)
{
    std::istringstream iss(rawLine);
    std::string prefix, code, target, visibility, channelName, colon;
    iss >> prefix >> code >> target >> visibility >> channelName;

    std::string remainder;
    std::getline(iss, remainder);

    std::size_t pos = remainder.find(':');
    std::string nickList = (pos != std::string::npos) ? remainder.substr(pos + 1) : remainder;
    std::istringstream nickStream(nickList);

    Channel &channel = channels[channelName];
    channel.name = channelName;
    channel.users.clear();

    std::string nick;
    while (nickStream >> nick)
    {
        std::string status;
        if (!nick.empty() && (nick[0] == '@' || nick[0] == '+'))
        {
            status = nick.substr(0, 1);
            nick = nick.substr(1);
        }

        User *user = findOrCreateUser(nick);
        user->status = status; // optional: status may differ across channels

        channel.users.push_back(user);
    }
}

User *IRCClient::findOrCreateUser(const std::string &nick)
{
    auto [it, inserted] = users.try_emplace(nick, User{nick, {}});
    return &it->second;
}

void IRCClient::joinChannels(const std::vector<std::string> &channels)
{
    for (const auto &chan : channels)
    {
        std::string join = "JOIN #" + chan + "\n";
        asio::write(socket, asio::buffer(join));
    }
}

void IRCClient::startInputLoop()
{
    inputThread = std::thread([this]()
                              {
        try {
            while (running.load()) {
                std::string input = ui.getInput();
                sanitizeInput(input);
                if (input.empty()) {
                    logger.log("Socket client disconnected");
                    signoff(joinedChannels, "eIRC ( https://github.com/jesse-greathouse/eIRC )");
                    break;
                }

                bool handled = false;
                for (const auto &command : commands) {
                    if (command.predicate(input)) {
                        command.handler(*this, input);
                        handled = true;
                        break;
                    }
                }

                if (!handled) {
                    throw std::runtime_error(":client error :Unrecognized command: \"" + input + "\"");
                }

                if (!isJoined()) {
                    break;
                }
            }
        }
        catch (const std::exception &ex) {
            const std::string message = "Fatal error in input thread: " + std::string(ex.what());
            logger.log(message);
            logger.flush(); // <-- manually flush the logger
            std::exit(1);
        } });
}

void IRCClient::readLoop(const std::vector<std::string> &channels)
{
    std::array<char, 1024> buf;
    asio::error_code error;
    std::string buffer;

    while (true)
    {
        std::size_t len = socket.read_some(asio::buffer(buf), error);
        if (error == asio::error::eof || error)
            break;

        buffer += std::string(buf.data(), len);
        size_t pos;

        while ((pos = buffer.find("\n")) != std::string::npos)
        {
            std::string line = buffer.substr(0, pos);

            if (pos > 0 && buffer[pos - 1] == '\r')
            {
                buffer.erase(0, pos + 1); // remove \r\n
            }
            else
            {
                buffer.erase(0, pos + 1); // remove \n only
            }

            logger.log(line);
            ui.drawOutput(line);

            // Loops through the event handlers.
            // Executes a list of registered handlers if its the right event.
            for (const auto &[key, handler] : eventHandlers)
            {
                if (handler.predicate(line))
                {
                    for (const auto &fn : handler.handlers)
                        fn(*this, line); // Pass the IRCClient reference
                    break;
                }
            }
        }
    }

    logger.log("Disconnected.");
    ui.drawOutput("Disconnected.");
}

void IRCClient::signoff(const std::vector<std::string> &channels, const std::string &quitMessage)
{
    for (const auto &chan : channels)
    {
        std::string partMsg = "PART #" + chan + " :Bye bye\n";
        asio::write(socket, asio::buffer(partMsg));
        logger.log("→ " + partMsg);
    }

    std::string quitMsg = "QUIT :" + quitMessage + "\n";
    asio::write(socket, asio::buffer(quitMsg));
    logger.log("→ " + quitMsg);
    stop();
}

void IRCClient::stop()
{
    setJoined(false); // stops the loop by protocol logic
    running = false;
    socket.close();
}

std::string IRCClient::formatUserList(const std::string &channelName) const
{
    std::string chan = channelName;
    while (!chan.empty() && (chan.back() == '\r' || chan.back() == '\n'))
        chan.pop_back();
    if (chan.empty())
        return ":client error :No channel specified.";
    if (chan[0] != '#')
        chan = "#" + chan;

    auto it = channels.find(chan);
    if (it == channels.end() || it->second.users.empty())
        return ":client error :channel " + chan + " not found or no users.";

    std::string response;
    for (const User *user : it->second.users)
    {
        if (!response.empty())
            response += ", ";
        response += user->status + user->nick;
    }

    return ":client users " + chan + " :" + response;
}

std::string IRCClient::formatChannelList() const
{
    if (channels.empty())
        return ":client channels: ";

    std::string response = ":client channels :";
    bool first = true;
    for (const auto &[channel, _] : channels)
    {
        if (!first)
            response += ", ";
        response += channel;
        first = false;
    }
    return response;
}

void IRCClient::addEventHandler(const std::string &eventKey, std::function<void(IRCClient &, const std::string &)> handler)
{
    auto it = eventHandlers.find(eventKey);
    if (it == eventHandlers.end())
    {
        throw std::runtime_error(":client error :add handler event key '" + eventKey + "' is not registered.");
    }

    it->second.handlers.push_back(std::move(handler));
}

void IRCClient::sanitizeInput(std::string &input)
{
    while (!input.empty() && (input.back() == '\n' || input.back() == '\r'))
    {
        input.pop_back();
    }
}

void IRCClient::joinInputLoop()
{
    if (inputThread.joinable())
    {
        inputThread.join();
    }
}

const std::map<std::string, Channel> &IRCClient::getChannels() const
{
    return channels;
}

const std::map<std::string, User> &IRCClient::getUsers() const
{
    return users;
}

const std::vector<std::string> &IRCClient::getJoinedChannels() const
{
    return joinedChannels;
}

Logger &IRCClient::getLogger()
{
    return logger;
}

bool IRCClient::isJoined() const
{
    return joined.load();
}

bool IRCClient::getJoined() const
{
    return joined.load();
}

void IRCClient::setJoined(bool joined)
{
    this->joined.store(joined);
}

IOAdapter &IRCClient::getUi()
{
    return ui;
}

asio::ip::tcp::socket &IRCClient::getSocket()
{
    return socket;
}
