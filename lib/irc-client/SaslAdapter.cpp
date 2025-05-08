#include "SaslAdapter.hpp"
#include "IRCEventKeys.hpp"
#include <asio/write.hpp>
#include <functional>

void SaslAdapter::negotiate(IRCClient &client)
{
	// Start CAP LS
	client.writeToServer("CAP LS 302\n");

	// On CAP LS reply, request SASL
	client.addEventHandler(IRCEventKey::Cap,
						   [&](IRCClient &, const std::string &line)
						   {
							   if (line.rfind("CAP * LS", 0) == 0 && line.find("sasl") != std::string::npos)
							   {
								   client.writeToServer("CAP REQ :sasl\n");
							   }
						   });

	// 3) On CAP ACK, *signal* over the UI socket that we need the AUTHENTICATE
	client.addEventHandler(IRCEventKey::Cap,
						   [&](IRCClient &, const std::string &line)
						   {
							   if (line == "CAP * ACK :sasl")
							   {
								   // debug: note that SASL ACK arrived
								   client.getLogger().log("[DEBUG] Server acknowledged SASL, awaiting client-side AUTHENTICATE");
							   }
						   });

	// Handle numeric replies:
	// Success → finish cap
	client.addEventHandler("903",
						   [&](IRCClient &, const std::string &)
						   {
							   client.writeToServer("CAP END\n");
						   });

	// Failures: 904–907
	auto makeHandler = [&](const char *code, const char *msg)
	{
		client.addEventHandler(code,
							   [code, msg](IRCClient &c, const std::string &line)
							   {
								   std::string out = std::string("! SASL error (") + code + "): " + msg;
								   c.getLogger().log(out);
								   c.getUi().drawOutput(out);
							   });
	};
	makeHandler("904", "SASL authentication failed");
	makeHandler("905", "SASL mechanism too long");
	makeHandler("906", "SASL aborted");
	makeHandler("907", "SASL already in progress");
}
