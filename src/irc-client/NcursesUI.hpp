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
