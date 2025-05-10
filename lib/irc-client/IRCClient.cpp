// File: IRCClient.cpp
// Requires: C++23
// Purpose: Implements the core IRC client logic including command registration, event dispatching,
//          async input/output loops, and channel/user state management using C++23 features like
//          lambda expressions with captures, structured bindings, and improved standard containers.

#include "IRCClient.hpp"
#include "IRCEventKeys.hpp"
#include <thread>
#include <sstream>
#include <array>
#include <system_error>
#include <asio/error_code.hpp>

#include "Commands/QuitCommand.hpp"
#include "Commands/UsersCommand.hpp"
#include "Commands/ChannelsCommand.hpp"
#include "Commands/InputCommand.hpp"

IRCClient::IRCClient(asio::io_context &context, Logger &logger, IOAdapter &ui, const std::vector<std::string> &channels)
    : ioContext(context), logger(logger), ui(ui), channelsJoined(false), joinedChannels(channels)
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

IRCClient::~IRCClient()
{
    joinInputLoop();
}

void IRCClient::registerCommands()
{
    commands = {
        QuitCommand,
        UsersCommand,
        ChannelsCommand,
        InputCommand};
}

void IRCClient::registerEventHandlers()
{
    eventHandlers[IRCEventKey::Ping] = EventHandler{
        [](const std::string &line)
        { return line.starts_with("PING "); },
        {}};

    eventHandlers[IRCEventKey::RplNameReply] = EventHandler{
        [](const std::string &line)
        { return line.find(" 353 ") != std::string::npos; },
        {}};

    eventHandlers[IRCEventKey::MotdEnd] = EventHandler{
        [this](const std::string &line)
        {
            return !isChannelsJoined()
                && (line.find("376") != std::string::npos || line.find("422") != std::string::npos);
        },
        {}};

    eventHandlers[IRCEventKey::Privmsg] = EventHandler{
        [](const std::string &line)
        { return line.find(" PRIVMSG ") != std::string::npos; },
        {}};

    eventHandlers[IRCEventKey::Cap] = EventHandler{
        [](const std::string &line)
        { return line.find(" CAP ") != std::string::npos; },
        {}};

    eventHandlers[IRCEventKey::Whois] = EventHandler{
        [](const std::string &line)
        {
            return line.find(" 311 ") != std::string::npos ||
                   line.find(" 312 ") != std::string::npos ||
                   line.find(" 317 ") != std::string::npos ||
                   line.find(" 318 ") != std::string::npos ||
                   line.find(" 319 ") != std::string::npos;
        },
        {}};

    // 903 = SASL authentication successful
    eventHandlers["903"] = EventHandler{
        [](const std::string &line)
        { return line.find(" 903 ") != std::string::npos; },
        {}};
    // 904 = SASL authentication failed
    eventHandlers["904"] = EventHandler{
        [](const std::string &line)
        { return line.find(" 904 ") != std::string::npos; },
        {}};
    // 905 = SASL mechanism too long
    eventHandlers["905"] = EventHandler{
        [](const std::string &line)
        { return line.find(" 905 ") != std::string::npos; },
        {}};
    // 906 = SASL aborted
    eventHandlers["906"] = EventHandler{
        [](const std::string &line)
        { return line.find(" 906 ") != std::string::npos; },
        {}};
    // 907 = SASL already in progress
    eventHandlers["907"] = EventHandler{
        [](const std::string &line)
        { return line.find(" 907 ") != std::string::npos; },
        {}};
}

template <typename SocketType>
void IRCClient::writeToSocket(SocketType &socket, const std::string &message)
{
    // explicit data pointer + length
    asio::write(socket,
                asio::buffer(message.data(), message.size()));
}

void IRCClient::connect(const std::string &server, int port)
{
    useTls = (port == 6697);
    asio::ip::tcp::resolver resolver(ioContext);
    auto endpoints = resolver.resolve(server, std::to_string(port));

    if (useTls)
    {
        sslContext.emplace(asio::ssl::context::tlsv12_client);
        sslContext->set_verify_mode(asio::ssl::verify_none);

        sslSocket = std::make_unique<ssl_stream>(ioContext, *sslContext);
        asio::connect(sslSocket->next_layer(), endpoints);

        // → Perform TLS handshake with explicit error handling
        asio::error_code ec;
        sslSocket->handshake(asio::ssl::stream_base::client, ec);
        if (ec)
        {
            throw std::runtime_error("TLS handshake failed: " + ec.message());
        }

        socketWriter = [this](const std::string &msg)
        {
            writeToSocket(*sslSocket, msg);
        };
    }
    else
    {
        plainSocket = std::make_unique<tcp_socket>(ioContext);
        asio::connect(*plainSocket, endpoints);
        socketWriter = [this](const std::string &msg)
        {
            writeToSocket(*plainSocket, msg);
        };
    }
}

void IRCClient::authenticate(const std::string &nick, const std::string &user, const std::string &realname)
{
    writeToServer(std::format("NICK {}\nUSER {} 0 * :{}\n", nick, user, realname));
}

std::size_t IRCClient::readFromServer(char *buf, std::size_t size)
{
    if (useTls && sslSocket)
        return sslSocket->read_some(asio::buffer(buf, size));
    if (plainSocket)
        return plainSocket->read_some(asio::buffer(buf, size));
    throw std::runtime_error("No socket available to read data.");
}

void IRCClient::startInputLoop()
{
    inputThread = std::thread([this]
        {
        try {
            while (running.load()) {
                std::string input = ui.getInput();
                sanitizeInput(input);
                if (input.empty()) {
                    logger.log("Socket client disconnected");
                    signoff(getChannels(), "eIRC ( https://github.com/jesse-greathouse/eIRC )");
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

            }
        } catch (const std::exception &ex) {
            const std::string message = "Fatal error in input thread: " + std::string(ex.what());
            logger.log(message);
            logger.flush();
            std::exit(1);
        } });
}

void IRCClient::readLoop(const std::vector<std::string> &channels)
{
    std::array<char, 1024> buf;
    std::string buffer;

    while (running.load())
    {
        std::size_t len = readFromServer(buf.data(), buf.size());
        if (len == 0)
            break;

        buffer.append(buf.data(), len);

        std::size_t pos;
        while ((pos = buffer.find('\n')) != std::string::npos)
        {
            std::string line = buffer.substr(0, pos);
            if (!line.empty() && line.back() == '\r')
                line.pop_back();

            buffer.erase(0, pos + 1);

            logger.log(line);
            ui.drawOutput(line);

            for (const auto &[key, handler] : eventHandlers)
            {
                if (handler.predicate(line))
                {
                    for (const auto &fn : handler.handlers)
                        fn(*this, line);
                    break;
                }
            }
        }
    }

    logger.log("Disconnected.");
    ui.drawOutput("Disconnected.");
}

template <typename SocketType>
void writeToServer(SocketType &socket, const std::string &message)
{
    asio::write(socket,
                asio::buffer(message.data(), message.size()));
}

void IRCClient::writeToServer(const std::string &message)
{
    if (!socketWriter)
        throw std::runtime_error("Socket writer not initialized");
    socketWriter(message);
}

void IRCClient::handlePing(const std::string &message)
{
    // 1) Extract the ping payload
    std::string payload = message.substr(message.find(':') + 1);
    payload.erase(std::remove(payload.begin(), payload.end(), '\r'), payload.end());
    payload.erase(std::remove(payload.begin(), payload.end(), '\n'), payload.end());

    // 2) Build the PONG response
    std::string response = "PONG :" + payload + "\n";

    // 3) Attempt send, log success; on error, catch and log exception
    try
    {
        writeToServer(response);
        logger.log("→ " + response.substr(0, response.size() - 1));
    }
    catch (const std::exception &ex)
    {
        logger.log("! PONG failed: " + std::string(ex.what()));
    }
}

void IRCClient::handleNameReply(const std::string &rawLine)
{
    std::istringstream iss(rawLine);
    std::string prefix, code, target, visibility, channelName, remainder;
    iss >> prefix >> code >> target >> visibility >> channelName;
    std::getline(iss, remainder);

    auto pos = remainder.find(':');
    auto nickList = (pos != std::string::npos) ? remainder.substr(pos + 1) : remainder;
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
            status = nick[0];
            nick.erase(0, 1);
        }
        auto *user = findOrCreateUser(nick);
        user->status = status;
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
        writeToServer(join);
    }
}

void IRCClient::signoff(const std::map<std::string, Channel> &channels, const std::string &quitMessage)
{
    for (const auto &pair : channels)
    {
        const std::string &chan = pair.first;
        std::string partMsg = "PART " + chan + " :Bye bye\n";
        writeToServer(partMsg);
        logger.log("→ " + partMsg);
    }

    std::string quitMsg = "QUIT :" + quitMessage + "\n";
    writeToServer(quitMsg);
    logger.log("→ " + quitMsg);

    stop();
}

void IRCClient::stop()
{
    running = false;
    if (plainSocket)
        plainSocket->close();
    if (sslSocket)
        sslSocket->lowest_layer().close();
}

std::string IRCClient::formatUserList(const std::string &channelName) const
{
    std::string chan = channelName;
    chan.erase(std::remove_if(chan.begin(), chan.end(), [](char c)
                              { return c == '\n' || c == '\r'; }),
               chan.end());
    if (chan.empty())
        return ":client error :No channel specified.";
    if (!chan.starts_with('#'))
        chan.insert(chan.begin(), '#');

    auto it = channels.find(chan);
    if (it == channels.end() || it->second.users.empty())
        return std::format(":client error :channel {} not found or no users.", chan);

    std::string response;
    for (const User *user : it->second.users)
        response += std::format("{}{}, ", user->status, user->nick);

    if (!response.empty())
        response.pop_back(), response.pop_back();
    return std::format(":client users {} :{}", chan, response);
}

std::string IRCClient::formatChannelList() const
{
    if (channels.empty())
        return ":client channels: ";
    std::string response;
    for (auto it = channels.begin(); it != channels.end(); ++it)
    {
        if (!response.empty())
            response += ", ";
        response += it->first;
    }
    return ":client channels :" + response;
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
    input.erase(std::remove_if(input.begin(), input.end(), [](char c)
                               { return c == '\r' || c == '\n'; }),
                input.end());
}

void IRCClient::joinInputLoop()
{
    // Tell the loop to exit (unblocks read()/getInput())
    stop();

    if (inputThread.joinable())
        inputThread.join();
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

bool IRCClient::isChannelsJoined() const noexcept
{
    return channelsJoined.load(std::memory_order_relaxed);
}

void IRCClient::setChannelsJoined(bool value)
{
    channelsJoined.store(value, std::memory_order_relaxed);
}

IOAdapter &IRCClient::getUi()
{
    return ui;
}

template <>
asio::ip::tcp::socket &IRCClient::getSocket<asio::ip::tcp::socket>()
{
    if (!plainSocket)
        throw std::runtime_error("Plain socket not initialized");
    return *plainSocket;
}

template <>
asio::ssl::stream<asio::ip::tcp::socket> &IRCClient::getSocket<asio::ssl::stream<asio::ip::tcp::socket>>()
{
    if (!sslSocket)
        throw std::runtime_error("TLS socket not initialized");
    return *sslSocket;
}
