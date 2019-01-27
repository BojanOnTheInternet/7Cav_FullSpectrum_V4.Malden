#include "..\..\OO\OO.h"

SERVER_SpecialOperationsCommand = [] call OO_CREATE(SpecialOperationsCommand);

SpecialOperations_PlayerConnected =
{
	_this spawn
	{
		params ["_id", "_uid", "_name", "_jip", "_owner"];
	
		if (_name == "__SERVER__") exitWith {}; // Server declaring its creation

		private _player = objNull;
		[{ _player = [_uid] call SERVER_GetPlayerByUID; not isNull _player }, 30, 1] call JB_fnc_timeoutWaitUntil;

		[_player] call OO_METHOD(SERVER_SpecialOperationsCommand,SpecialOperationsCommand,NotifyPlayer);
	};
};

addMissionEventHandler ["PlayerConnected", SpecialOperations_PlayerConnected];

SpecialOperations_RequestMission =
{
	if (SpecialOperations_RunState == "suspend") exitWith { ["Special operations have been suspended.", ["title"]] call SPM_Mission_Message};
	if (SpecialOperations_RunState == "stop") exitWith { ["Special operations command is offline.", ["title"]] call SPM_Mission_Message};

	private _player = objNull;
	{
		if (owner _x == remoteExecutedOwner) exitWith { _player = _x };
	} forEach allPlayers;

	if (not isNull _player) then
	{
		[_player] call OO_METHOD(SERVER_SpecialOperationsCommand,SpecialOperationsCommand,RequestMission);
	};
};

