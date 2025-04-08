#include "ArgParser.hpp"
#include <cassert>
#include <iostream>

int main()
{
	const char *argv[] = {
		"test",
		"--nick=TestBot",
		"--server=irc.example.com",
		"--port=6667",
		"--channels=general,test",
		"--log=test.log"};
	ArgParser parser(6, const_cast<char **>(argv));
	ParsedArgs args = parser.getArgs();

	assert(args.nick == "TestBot");
	assert(args.server == "irc.example.com");
	assert(args.port == 6667);
	assert(args.channels == "general,test");
	assert(args.logPath == "test.log");

	std::cout << "ArgParser_test passed." << std::endl;
	return 0;
}
