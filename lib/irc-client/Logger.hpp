// File: Logger.hpp
// Requires: C++23
// Purpose: Declares the Logger class, which provides simple logging functionality for writing
//          messages to both a file and standard output. Supports message trimming and manual flushing.

#pragma once

#include <string>
#include <fstream>

class Logger
{
public:
	explicit Logger(const std::string &path);
	void log(const std::string &message);
	void flush();

private:
	std::ofstream out;
};
