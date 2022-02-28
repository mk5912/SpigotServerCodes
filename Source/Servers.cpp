// This is an independent project of an individual developer. Dear PVS-Studio, please check it.

// PVS-Studio Static Code Analyzer for C, C++, C#, and Java: https://pvs-studio.com

#include "Servers.h"

void servers_Initialise(){

}

const char getServers() {
	const char* servers = "Debug";
	return *servers;
}

server setActiveServer(int index) {
	server tempServer;
	tempServer.serverID = index;
	server activeServer;
	deleteServer(tempServer);
	return activeServer;
}

void addServer(server name, const char serverType) {
	if (name.bungee) {

	}
}

void deleteServer(server name) {

}
