/*
* Header file for all server related functions.
*/

#ifndef MAINONLY

#include <string>
#include <stdio.h>

#ifndef SERVERS_H
#define SERVERS_H


// Server class for creating new servers.
class server {
private:
	int size = 1;
	FILE master = fopen(strcat(appdata,"/mk5912/spigotServers.csv"), "a+");
public:
	int serverID; // Server ID/ index number.
	int serverPort;
	const char serverName; // Current servers name.
	const char version;
	const char dir;
	const char *motd = "^&2 This is a custom Minecraft server using ServerApplication from mk5912^!";
	bool bungee;
	world *worlds = new world[size]; // List of all child worlds linked to the server.
	
	// Creates a new world for a server.
	void createWorld(world name) {
		name.worldName = "&name";
		name.parent = serverID;
		for (int i = 0; i <= size; i++) {
			if (strlen(worlds[i].worldName) > 0) {
				worlds[i] = name;
			}
			else {
				if (size == i) {
					size++;
					worlds[size] = name;
				}
			}
			name.worldID = i;
		}
	}

	// Deletes a world linked to the server.
	void deleteWorld(char name) {
		return;
	}

	// Terminates a server so a new one can be loaded.
	void terminate() {
		delete[] worlds;
		worlds = NULL;
	}
};

// World class for tracking on servers.
class world : public server {
public:
	int parent, worldID, difficulty, gamemode, worldPort = 0;
	const char *worldName = "World";
	bool cmdBlock, allowFlight, whitelist, pvpEnable, fGM = false;
};

// Returns all server names.
const char getServers();

// Sets the selected server to be the active server.
server setActiveServer(int index);

// Adds a new server to run.
void addServer(server serverName, const char serverType);

// Deletes a server and all it's respective worlds.
void deleteServer(server serverName);

// Starts the currently selected server and runs the connected worlds.
void startServer();

// Restarts all running worlds on the server.
void restartServer();

// Sends the stop command to all running worlds on the server.
void stopServer();




#endif // !SERVERS_H


#endif // !MAINONLY