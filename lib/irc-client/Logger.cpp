#include "Logger.hpp"
#include <iostream>

Logger::Logger(const std::string &path)
{
	out.open(path, std::ios::out | std::ios::app);
	if (!out)
	{
		std::cerr << "Failed to open log file: " << path << std::endl;
	}
}

void Logger::log(const std::string &message)
{
	std::string trimmed = message;

	// Remove trailing \r and \n
	while (!trimmed.empty() && (trimmed.back() == '\r' || trimmed.back() == '\n'))
	{
		trimmed.pop_back();
	}

	if (out.is_open())
		out << trimmed << std::endl;
	std::cout << trimmed << std::endl;
}

void Logger::flush()
{
	if (out.is_open())
	{
		out.flush();
	}
}
