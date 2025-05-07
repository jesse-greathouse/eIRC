#include "NickServAdapter.hpp"
#include "IRCEventKeys.hpp"

void NickServAdapter::negotiate(IRCClient &client)
{
	client.addEventHandler(IRCEventKey::MotdEnd,
						   [this](IRCClient &c, const std::string &)
						   {
							   c.writeToServer("PRIVMSG NickServ :IDENTIFY " + pass_ + "\n");
						   });
}
