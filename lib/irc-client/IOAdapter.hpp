// File: IOAdapter.hpp
// Requires: C++23
// Purpose: Declares the IOAdapter abstract base class, which defines a unified interface
//          for user input/output handling. Allows interchangeable implementations such as
//          NcursesUI and UnixSocketUI.

#pragma once

#include <string>

// Abstract base class for user input/output handling
class IOAdapter
{
public:
	virtual ~IOAdapter() = default;

	virtual void init() = 0;
	virtual void shutdown() = 0;
	virtual void drawOutput(const std::string &line) = 0;
	virtual std::string getInput() = 0;
};
