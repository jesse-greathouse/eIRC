#include "IRCClient.hpp"
#include <thread>
#include <sstream>

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

void IRCClient::handleRplNameReply(const std::string &rawLine)
{
    std::istringstream iss(rawLine);
    std::string prefix, code, target, visibility, channel, colon;

    iss >> prefix >> code >> target >> visibility >> channel;

    std::string remainder;
    std::getline(iss, remainder);

    // Now extract nick list after the first ':' in the remainder
    std::size_t pos = remainder.find(':');
    std::string nickList = (pos != std::string::npos) ? remainder.substr(pos + 1) : remainder;

    std::istringstream nickStream(nickList);
    std::string nick;
    std::vector<User> updatedUsers;

    while (nickStream >> nick)
    {
        std::string status;
        if (!nick.empty() && (nick[0] == '@' || nick[0] == '+'))
        {
            status = nick.substr(0, 1);
            nick = nick.substr(1);
        }

        updatedUsers.push_back({nick, status});
    }

    channels[channel] = std::move(updatedUsers);
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
    std::thread([this]()
                {
        while (true)
        {
            std::string input = ui.getInput();

            if (input.empty())
            {
                logger.log("Socket client disconnected");
                signoff(joinedChannels, "eIRC ( https://github.com/jesse-greathouse/eIRC )");
                break;
            }

            while (!input.empty() && (input.back() == '\n' || input.back() == '\r'))
            {
                input.pop_back();
            }

            if (input == "/quit")
            {
                signoff(joinedChannels, "eIRC ( https://github.com/jesse-greathouse/eIRC )");
                break;
            }

            if (input.rfind("/input ", 0) == 0)
            {
                input = input.substr(7); // Remove "/input " prefix
            }

            if (input.rfind("/users ", 0) == 0)
            {
                std::string channel = input.substr(7); // Extract channel name
                ui.drawOutput(formatUserList(channel));
                continue;
            }

            if (input == "/channels")
            {
                ui.drawOutput(formatChannelList());
                continue;
            }

            std::string message = input + "\n";
            asio::write(socket, asio::buffer(message));
            logger.log("→ " + input);
        } })
        .detach();
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

            if (line.substr(0, 5) == "PING ")
            {
                handlePing(line);
            }
            else if (line.find(" 353 ") != std::string::npos)
            {
                handleRplNameReply(line);
            }

            if (!joined && (line.find("376") != std::string::npos || line.find("422") != std::string::npos))
            {
                joinChannels(channels);
                joined = true;
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

    socket.close();
}

std::string IRCClient::formatUserList(const std::string &channelName) const
{
    std::string channel = channelName;

    // Trim trailing \r or \n
    while (!channel.empty() && (channel.back() == '\r' || channel.back() == '\n'))
    {
        channel.pop_back();
    }

    if (channel.empty())
        return "No channel specified.";

    if (channel[0] != '#')
        channel = "#" + channel;

    auto it = channels.find(channel);
    if (it == channels.end())
    {
        std::string knownChannels;
        for (const auto &[chan, _] : channels)
        {
            if (!knownChannels.empty())
                knownChannels += ", ";
            knownChannels += chan;
        }

        return "Channel " + channel + " not found or no users." + (knownChannels.empty() ? "" : " (Current channels are: " + knownChannels + ")");
    }

    std::string response;
    for (const auto &user : it->second)
    {
        if (!response.empty())
            response += ", ";
        response += user.status + user.nick;
    }

    return "Users in " + channel + ": " + response;
}

std::string IRCClient::formatChannelList() const
{
    if (channels.empty())
        return "No channels joined or received from server yet.";

    std::string response = "Channels: ";
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
