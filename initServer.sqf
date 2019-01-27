diag_log "initServer start";

#include "SPM\strongpoint.h"
//#include "\serverscripts\zeusserverscripts\zeus_assigner.sqf" // Zeus assigner

addMissionEventHandler ["PlayerConnected", SERVER_PlayerConnected];
addMissionEventHandler ["PlayerDisconnected", SERVER_PlayerDisconnected];

_null = [] execVM "scripts\sessionTimeMessagesInit.sqf";

// Make sure armed civilians won't attack NATO
civilian setFriend [west, 1];
// Make sure AAF won't attack CSAT
independent setFriend [east, 1];
east setFriend [independent, 1];
// Make sure AAF will attack NATO
independent setFriend [west, 0];

//BUG: Fool BIS_fnc_drawMinefields into believing that it's already running.  This turns off the automatic display of minefields on the map.  The difficulty setting in the server configuration file doesn't seem to work.
bis_fnc_drawMinefields_active = true;

// Start times selected randomly throughout the daylight hours between sunrise and one hour before sunset
waitUntil { time > 0 }; // Allow time subsystem to initialize so that missionStart is correct
private _date = missionStart select [0, 5];

private _times = [_date] call BIS_fnc_sunriseSunsetTime;
private _startTime = (_times select 0) + (random ((_times select 1) - (_times select 0) - 1));
private _startHour = floor _startTime;
private _startMinute = (_startTime - _startHour) * 60;

_date set [3, _startHour];
_date set [4, _startMinute];

setDate _date;

// Markers of format LOCATION_<type>_<id> are turned into locations of the specified type and marker text.  The id is optional and is used to make the marker names unique.  The markers will be hidden.
private _location = 0;
{
	(_x splitString "_") params ["_unused", "_type"];

	private _location = createLocation ([_type, getMarkerPos _x] + getMarkerSize _x);
	_location setText markerText _x;

	_x setMarkerAlpha 0;
} forEach (allMapMarkers select { _x find "LOCATION_" == 0 });

[] call compile preprocessFile ("scripts\configure" + worldName + "Server.sqf"); // Island-specific modifications
[] call compile preprocessFile "scripts\weatherInit.sqf"; // Variable weather

Advance_RunState = ["stop", "run"] select (["Advance"] call Params_GetParamValue);
_null = [] execVM "mission\Advance\missionControl.sqf";

SpecialOperations_RunState = ["stop", "run"] select (["SpecialOperations"] call Params_GetParamValue);
_null = [] execVM "mission\SpecialOperations\missionControl.sqf";

// Delete missions when appropriate
_null = [] execVM "mission\missionMonitor.sqf";

// Stuff involving players entering enemy-held areas
[] call SERVER_MonitorProximityRoundRequests;

["Initialize"] call BIS_fnc_dynamicGroups;

[Radio_Radios] call Radio_fnc_customServerInit;

SA_MAX_TOWED_CARGO = 1;
_null = [] execVM "ASL_AdvancedSlingLoading\functions\fn_advancedSlingLoadInit.sqf";
_null = [] execVM "AR_AdvancedRappelling\functions\fn_advancedRappellingInit.sqf";
_null = [] execVM "AT_AdvancedTowing\functions\fn_advancedTowingInit.sqf";
_null = [] execVM "AUR_AdvancedUrbanRappelling\functions\fn_advancedUrbanRappellingInit.sqf";

_null = [] execVM "scripts\decals.sqf";

enableEnvironment [false, true];

diag_log "initServer end";