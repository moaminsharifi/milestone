#include "stream.h"

int main(int argc, char **argv)
{
	int number = 0;

	get(&number);
	print(number);

	return 0;
}
