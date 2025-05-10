#include <asio/write.hpp>
#include <functional>
#include "SaslAdapter.hpp"
#include "IRCEventKeys.hpp"

void SaslAdapter::negotiate(IRCClient &client)
{
	// Advertise capabilities
	client.writeToServer("CAP LS 302\n");

	// When LS arrives, ask for SASL
	client.addEventHandler(IRCEventKey::Cap,
						   [&](IRCClient &c, const std::string &line)
						   {
							   if (line.find(" LS ") != std::string::npos && line.find("sasl") != std::string::npos)
							   {
								   c.writeToServer("CAP REQ :sasl\n");
							   }
							   else if (line.find(" ACK :sasl") != std::string::npos)
							   {
								   c.writeToServer("AUTHENTICATE PLAIN\n");
							   }
						   });

	// On numeric 903 (success), finish capability negotiation —
	client.addEventHandler("903",
						   [&](IRCClient &c, const std::string &)
						   {
							   c.writeToServer("CAP END\n");
						   });

	// — Step F: On 904–907 (failures), log, notify UI, and end CAP —
	auto makeHandler = [&](const char *code, const char *msg)
	{
		client.addEventHandler(code,
							   [code, msg](IRCClient &c, const std::string &)
							   {
								   std::string out = std::string("! SASL error (") + code + "): " + msg;
								   c.getLogger().log(out);
								   c.getUi().drawOutput(out);
								   c.writeToServer("CAP END\n");
							   });
	};
	makeHandler("904", "authentication failed");
	makeHandler("905", "mechanism too long");
	makeHandler("906", "authentication aborted");
	makeHandler("907", "already in progress");
}
