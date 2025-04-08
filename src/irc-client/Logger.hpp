#pragma once

#include <string>
#include <fstream>

class Logger
{
public:
	explicit Logger(const std::string &path);
	void log(const std::string &message);

private:
	std::ofstream out;
};
