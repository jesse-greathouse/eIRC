// File: NcursesUI.hpp
// Requires: C++23
// Purpose: Declares the NcursesUI class, an ncurses-based implementation of the IOAdapter interface.
//          Provides a terminal-based interface for displaying IRC output and capturing user input in split panes.

#pragma once

#include <string>
#include <ncurses.h>
#include "IOAdapter.hpp"

class NcursesUI : public IOAdapter
{
public:
	void init() override;
	void shutdown() override;
	void drawOutput(const std::string &line) override;
	std::string getInput() override;

private:
	WINDOW *outputWin = nullptr;
	WINDOW *inputWin = nullptr;
};
