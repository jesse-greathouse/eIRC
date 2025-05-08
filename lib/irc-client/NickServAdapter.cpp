#include "NickServAdapter.hpp"
#include "IRCEventKeys.hpp"

void NickServAdapter::negotiate(IRCClient &client)
{
	client.addEventHandler(IRCEventKey::MotdEnd,
						   [&](IRCClient &c, const std::string &)
						   {
							   // debug: NickServ identify point reached
							   c.getLogger().log("[DEBUG] MOTD end; client ready for NickServ IDENTIFY");
						   });
}
