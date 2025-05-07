#pragma once
#include <string>

// Minimal Base64 encoder
static const char *B64_CHARS =
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

inline std::string encodeBase64(const std::string &in)
{
	std::string out;
	int val = 0, valb = -6;

	for (char ch : in)
	{
		unsigned char c = static_cast<unsigned char>(ch);
		val = (val << 8) + c;
		valb += 8;
		while (valb >= 0)
		{
			out.push_back(B64_CHARS[(val >> valb) & 0x3F]);
			valb -= 6;
		}
	}

	if (valb > -6)
	{
		out.push_back(
			B64_CHARS[((val << 8) >> (valb + 8)) & 0x3F]);
	}
	while (out.size() % 4)
	{
		out.push_back('=');
	}
	return out;
}
