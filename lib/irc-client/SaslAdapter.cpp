#include "SaslAdapter.hpp"
#include "Base64.hpp"
#include "IRCEventKeys.hpp"
#include <asio/write.hpp>
#include <functional>

void SaslAdapter::negotiate(IRCClient &client)
{
	// CAP LS
	client.writeToServer("CAP LS 302\n");
	// wait for CAP * LS reply and check for "sasl" in it
	client.addEventHandler(IRCEventKey::Cap,
						   [&](IRCClient &, const std::string &line)
						   {
							   if (line.find("sasl") != std::string::npos && line.rfind("CAP * LS", 0) == 0)
							   {
								   client.writeToServer("CAP REQ :sasl\n");
							   }
						   });

	// after ACK, send AUTHENTICATE
	client.addEventHandler(IRCEventKey::Cap,
						   [&](IRCClient &, const std::string &line)
						   {
							   if (line == "CAP * ACK :sasl")
							   {
								   // Build PLAIN payload from stored user_ and pass_
								   std::string raw = user_ + '\0' + user_ + '\0' + pass_;
								   std::string b64 = encodeBase64(raw);
								   client.writeToServer("AUTHENTICATE " + b64 + "\n");
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
