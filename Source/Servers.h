/*
* Header file for all server related functions.
*/

#include <string>
#include <stdio.h>
#include <random>
#include <filesystem>

#ifndef SERVERS_H
#define SERVERS_H

using namespace std;

#pragma warning(suppress : 4996)
char* appdata = getenv("appdata");

#pragma warning(suppress : 4996)
char* desktop = strcat(getenv("userprofile"),"\Desktop");
#pragma warning(suppress : 4996)
FILE* masterFile = fopen(strcat(appdata,"/mk5912/spigotServers.csv"), "a+");

namespace servers {
	// Server class for creating new servers.
	typedef class server {
	private:
		int size = 1;
	public:

		int serverPort = 25565;
		const char* serverName = "New_Server"; // Current servers name.
		const char* version = "latest";
		char* dir = desktop;
		unsigned int serverID = generateID(); // Server ID/ index number.
		const char* motd = "&&2 This is a custom Minecraft server using ServerApplication from mk5912!";
		bool bungee;
		int* worlds = new int[size]; // List of all child worlds linked to the server.

		// Creates a new world for a server.
		void createWorld(char* worldName) {
			world name;
			name.worldName = worldName;
			name.parent = serverID;

			while (!is_ID_Available(name.worldID) || name.worldID == NULL) {
				name.worldID = generateID();
			}
		}

		char* getWords() {

		}

		// Deletes a world linked to the server.
		void deleteWorld(char name) {

		}


		// Starts the currently selected server and runs the connected worlds.
		void startServer() {
			for (int i = 0; i < size; i++) {
				// return worlds[i];
			}
		}

		// Restarts all running worlds on the server.
		void restartServer() {

		}

		// Sends the stop command to all running worlds on the server.
		void stopServer() {

		}

		// Terminates a server so a new one can be loaded.
		void close() {
			delete[](worlds);
			worlds = NULL;
		}

		bool is_ID_Available(int id) {
			for (int i = 0; i < size; i++) {
				if (worlds[i] == id) {
					return false;
				}
			}
			return true;
		}

		// Applies default to functions.
		server() = default;
	};

	// World class for tracking on servers.
	typedef class world : public server {
	public:
		int worldID = 100000000;
		int parent, difficulty, gamemode, worldPort = 0;
		const char* worldName = "World";
		bool cmdBlock, allowFlight, whitelist, pvpEnable, fGM = false;



		world() = default;
	};

	// Initialises all the server data.
	void servers_Initialise();

	// Returns all server names.
	const char getServers();

	// Sets the selected server to be the active server.
	server setActiveServer(int index);

	// Adds a new server to run.
	void addServer(server serverName, const char serverType);

	// Deletes a server and all it's respective worlds.
	void deleteServer(server serverName);

	// Generates a randomised ID number.
	unsigned int generateID();
};
#endif // !SERVERS_H
