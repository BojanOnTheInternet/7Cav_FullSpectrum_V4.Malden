params [["_aircraft", objNull, [objNull]], ["_routes", [], [[]]], ["_height", 150, [0]], ["_speed", 200, [0]]];

if (isNull _aircraft) exitWith { diag_log "ERROR: JB_fnc_airTransportInitiailzeVehicle: null vehicle" };
if (count _routes == 0) exitWith { diag_log "ERROR: JB_fnc_airTransportInitiailzeVehicle: no routes" };

if (isNil "JB_AT_NamedRoutes") then { call JB_AT_InitializeNamedRoutes };

// Get the route data for this aircraft
private _routeData = [];
private _nameRoutes = _routes select { typeName _x == typeName "" };
if (count _nameRoutes > 0) then { _routeData append (JB_AT_NamedRoutes select { (_x select 0) in _nameRoutes }) };
private _arrayRoutes = _routes select { typeName _x == typeName [] };
if (count _arrayRoutes > 0) then { _routeData append _arrayRoutes };
_aircraft setVariable ["JB_AT_Aircraft_Routes", _routeData];

// Give the aircraft a pilot
private _group = [west, [[_aircraft], ["B_Helipilot_F", "private", [0,0,0], 0, { (_this select 0) allowDamage false }]], call SPM_Util_RandomSpawnPosition, 0, true, ["driver"]] call SPM_fnc_spawnGroup;
_aircraft lockDriver true;
_aircraft flyInHeight 10;

// Have the aircraft land at the closest landing pad that it uses on its routes.
private _route = [_routeData, getPos _aircraft, true] call JB_AT_ClosestInterface;
private _waypoint = [_group, _route select 1 select 0 select 1] call SPM_AddPatrolWaypoint;

private _landAndStartLoop =
{
	_this spawn
	{
		params ["_leader", "_units", "_passthrough"];

		_passthrough params ["_aircraft", "_height", "_speed"];

		scriptName "JB_AT_TransportLoopCurrentMission";

		_aircraft land "land";
		waitUntil { sleep 1; (getPosATL _aircraft) select 2 < 0.1 };
		_aircraft engineOn false;

		[_aircraft, _height, _speed] call JB_AT_TransportLoopCurrentMission;
	};
};

// When it gets there, land and start the transport loop
[_waypoint, _landAndStartLoop, [_aircraft, _height, _speed]] call SPM_AddPatrolWaypointStatements;