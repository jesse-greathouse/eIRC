#include "NcursesUI.hpp"

void NcursesUI::init()
{
	initscr();
	cbreak();
	noecho();
	curs_set(1);

	int h, w;
	getmaxyx(stdscr, h, w);
	int inputH = h / 10;
	int outputH = h - inputH;

	outputWin = newwin(outputH, w, 0, 0);
	inputWin = newwin(inputH, w, outputH, 0);

	scrollok(outputWin, TRUE);
	keypad(inputWin, TRUE);
	box(inputWin, 0, 0);
	wmove(inputWin, 1, 1);

	wrefresh(outputWin);
	wrefresh(inputWin);
}

void NcursesUI::shutdown()
{
	delwin(outputWin);
	delwin(inputWin);
	endwin();
}

void NcursesUI::drawOutput(const std::string &line)
{
	wprintw(outputWin, "%s\n", line.c_str());
	wrefresh(outputWin);
}

std::string NcursesUI::getInput()
{
	char buf[512];
	werase(inputWin);
	box(inputWin, 0, 0);
	mvwgetnstr(inputWin, 1, 1, buf, sizeof(buf) - 1);
	return std::string(buf);
}
