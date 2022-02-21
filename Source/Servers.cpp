// This is an independent project of an individual developer. Dear PVS-Studio, please check it.

// PVS-Studio Static Code Analyzer for C, C++, C#, and Java: https://pvs-studio.com

#ifndef MAINONLY

#include "Servers.h"

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

void addServer(server serverName, const char serverType) {

	if (serverName.bungee) {

	}
}

void deleteServer(server serverName) {

}

void startServer() {

}

void restartServer() {

}

void stopServer() {

}


#endif // !MAINONLY