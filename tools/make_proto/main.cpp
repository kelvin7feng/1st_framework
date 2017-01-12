#include "google.pb.h"
#include <iostream>
#include <stdio.h>

int main()
{
	using namespace google;
	Message msg;
	msg.set_server_id(111);
	msg.set_player_id(222);
	msg.set_pdata("ttttt");
	std::string str;
	msg.SerializeToString(&str);
	std::cout << str.c_str() << std::endl;

	Message tmpMsg;
	tmpMsg.ParseFromString(str);
	
	std::cout << "server id:" << tmpMsg.server_id() << std::endl;
	std::cout << "player id:" << tmpMsg.player_id() << std::endl;
	std::cout << "pdata :" << tmpMsg.pdata() << std::endl;
	return 0;
}
