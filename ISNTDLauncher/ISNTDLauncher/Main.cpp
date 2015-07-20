/** 
 ** PowerDefense, a 2D tower defense game (school project)
 ** Copyright (C) 2015 ALTHUSER Dimitri, BARBOTIN Nicolas, WITZ Benoît
 ** 
 ** This program is free software; you can redistribute it and/or
 ** modify it under the terms of the GNU General Public License
 ** as published by the Free Software Foundation; either version 2
 ** of the License, or (at your option) any later version.
 ** 
 ** This program is distributed in the hope that it will be useful,
 ** but WITHOUT ANY WARRANTY; without even the implied warranty of
 ** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ** GNU General Public License for more details.
 ** 
 ** You should have received a copy of the GNU General Public License
 ** along with this program; if not, write to the Free Software
 ** Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 **/

#include <Windows.h>
#include <string>

int CALLBACK WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	SYSTEM_INFO si;
	GetSystemInfo(&si);

	std::string arch;
	if(si.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_AMD64 || si.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_IA64)
		arch = "AMD64";
	else if(si.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_INTEL)
		arch = "x86";
	else {
		MessageBox(NULL, "Votre platforme n'est pas suportee.", "Erreur!", MB_ICONERROR | MB_OK);
		return -1;
	}

	char path[MAX_PATH];
	GetCurrentDirectory(MAX_PATH, path);

	std::string love(path);
	love += "\\love_";
	love += arch;
	love += "\\love.exe";

	std::string game(path);
	game += "\\td";

	std::string cmdLine;
	cmdLine += '\"';
	cmdLine += love;
	cmdLine += "\" \"";
	cmdLine += game;
	cmdLine += '\"';

	char *cl = new char[cmdLine.length() + 1];
	memcpy(cl, cmdLine.c_str(), cmdLine.length() + 1);

	STARTUPINFO start;
	PROCESS_INFORMATION pi;

	memset(&start, 0, sizeof(STARTUPINFO));
	start.cb = sizeof(STARTUPINFO);

	if(CreateProcess(love.c_str(), cl, NULL, NULL, FALSE, 0, NULL, game.c_str(), &start, &pi) != TRUE) {
		MessageBox(NULL, "Impossible de lancer le jeu.", "Erreur!", MB_ICONERROR | MB_OK);
		delete[] cl;
		return -2;
	}

	delete[] cl;
	return 0;
}
