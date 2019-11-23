/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

OO_TRACE_DECL(SPM_NeighborDirections) =
{
	params ["_road"];

	private _neighborDirections = [];
	{
		_neighborDirections pushBack [_road getDir _x, _x];
	} forEach roadsConnectedTo _road;

	_neighborDirections;
};

OO_TRACE_DECL(SPM_RoadFollow) =
{
	params ["_road", "_position", "_direction", "_distance"];

	private _distanceSqr = _distance * _distance;

	private _neighborDirections = [_road] call SPM_NeighborDirections;

	{
		private _sweep = ([_x select 0, _direction] call SPM_Util_AngleBetweenDirections);

		_x set [2, _x select 1];
		_x set [1, _x select 0];
		_x set [0, _sweep];
	} forEach _neighborDirections;

	_neighborDirections sort true;

	if ((_neighborDirections select 0) select 0 > 60) exitWith { [objNull, 0] };

	private _run = [_road, (_neighborDirections select 0) select 2, getPos _road, 300] call SPM_Nav_RoadRun;

	private _destination = [objNull, 0];
	private _lastRoad = _road;
	{
		if (_x distanceSqr _position > _distanceSqr) exitWith { _destination = [_x, _lastRoad getDir _x] };
		_lastRoad = _x;
	} forEach _run;

	if (isNull (_destination select 0)) then
	{
		_destination = [_run select (count _run - 1), _position, (_run select (count _run - 2)) getDir (_run select (count _run - 1)), _distance] call SPM_RoadFollow;
	};

	_destination
};

SPM_PatrolWaypointNumber = 0;

OO_TRACE_DECL(SPM_GetPatrolWaypointNumber) =
{
	params ["_waypoint"];

	private _statements = waypointStatements _waypoint;
	if (count _statements == 0) exitWith { diag_log "ERROR: SPM_AddPatrolWaypointStatements called on non-patrol waypoint."; -1 };

	parseNumber (_statements select 1);
};

// SPM_WaypointStatements [waypoint-statement, ...]
// waypoint-statement [waypoint-number, [statement, ...]]
// statement [code, passthrough]

OO_TRACE_DECL(SPM_ExecutePatrolWaypointStatements) =
{
	params ["_leader"];

	private _group = group _leader;

	private _patrolWaypointNumber = [[_group, currentWaypoint _group]] call SPM_GetPatrolWaypointNumber;
	private _patrolWaypointStatements = [];  { if (_x select 0 == _patrolWaypointNumber) exitWith { _patrolWaypointStatements = _x select 1; _x set [1, []] }} forEach (_group getVariable ["SPM_WaypointStatements", []]);

	{
		[_leader, units _group, _x select 1] call (_x select 0);
	} forEach _patrolWaypointStatements;
};

OO_TRACE_DECL(SPM_AddPatrolWaypointStatements) =
{
	params ["_waypoint", "_statements", ["_passthrough", []]];

	private _group = _waypoint select 0;
	private _waypointNumber = _waypoint select 1;

	private _patrolWaypointNumber = [_waypoint] call SPM_GetPatrolWaypointNumber;

	private _waypointStatements = _group getVariable "SPM_WaypointStatements";
	if (isNil "_waypointStatements") then { _waypointStatements = []; _group setVariable ["SPM_WaypointStatements", _waypointStatements] };

	private _patrolWaypointStatements = [];  { if (_x select 0 == _patrolWaypointNumber) exitWith { _patrolWaypointStatements = (_x select 1) }} forEach _waypointStatements;
	if (count _patrolWaypointStatements == 0) then
	{
		_waypointStatements pushBack [_patrolWaypointNumber, [[_statements, _passthrough]]];
	}
	else
	{
		_patrolWaypointStatements pushBack [_statements, _passthrough];
	};
};

OO_TRACE_DECL(SPM_AddPatrolWaypoint) =
{
	params ["_group", "_position", ["_radius", 0, [0]]];

	private _waypoint = _group addWaypoint ([_position, _radius] + (_this select [3, 1e3]));
	_waypoint setWaypointStatements ["true", format ["%1; [this] call SPM_ExecutePatrolWaypointStatements", SPM_PatrolWaypointNumber]];
	SPM_PatrolWaypointNumber = SPM_PatrolWaypointNumber + 1;

	_waypoint;
};

SPM_PW_GetWaypointAttributes =
{
	params ["_waypoint"];

	private _behaviour = waypointBehaviour _waypoint;
	private _combatMode = waypointCombatMode _waypoint;
	private _completionRadius = waypointCompletionRadius _waypoint;
	private _description = waypointDescription _waypoint;
	private _forceBehaviour = waypointForceBehaviour _waypoint;
	private _formation = waypointFormation _waypoint;
	private _housePosition = waypointHousePosition _waypoint;
	private _loiterRadius = waypointLoiterRadius _waypoint;
	private _loiterType = waypointLoiterType _waypoint;
	private _name = waypointName _waypoint;
	private _position = waypointPosition _waypoint;
	private _script = waypointScript _waypoint;
	private _speed = waypointSpeed _waypoint;
	private _statements = waypointStatements _waypoint;
	private _timeout = waypointTimeout _waypoint;
	private _type = waypointType _waypoint;
	private _visible = waypointVisible _waypoint;

	private _synchronizedWaypoints = synchronizedWaypoints _waypoint;
	private _attachedVehicle = waypointAttachedVehicle _waypoint;
	private _attachedObject = waypointAttachedVehicle _waypoint;

	[_behaviour, _combatMode, _completionRadius, _description, _forceBehaviour, _formation, _housePosition, _loiterRadius, _loiterType, _name, _position, _script, _speed, _statements, _timeout, _type, _visible, _synchronizedWaypoints, _attachedVehicle, _attachedObject]
};

SPM_PW_CreateWaypointFromAttributes =
{
	params ["_group", "_index", "_attributes"];

	private _newWaypoint = _group addWaypoint [_attributes select 10, _attributes select 2, _index];
	_newWaypoint setWaypointBehaviour (_attributes select 0);
	_newWaypoint setWaypointCombatMode (_attributes select 1);
	_newWaypoint setWaypointCompletionRadius (_attributes select 2);
	_newWaypoint setWaypointDescription (_attributes select 3);
	_newWaypoint setWaypointForceBehaviour (_attributes select 4);
	_newWaypoint setWaypointFormation (_attributes select 5);
	_newWaypoint setWaypointHousePosition (_attributes select 6);
	_newWaypoint setWaypointLoiterRadius (_attributes select 7);
	_newWaypoint setWaypointLoiterType (_attributes select 8);
	_newWaypoint setWaypointName (_attributes select 9);
	_newWaypoint setWaypointPosition [_attributes select 10, 0];
	_newWaypoint setWaypointScript (_attributes select 11);
	_newWaypoint setWaypointSpeed (_attributes select 12);
	_newWaypoint setWaypointStatements (_attributes select 13);
	_newWaypoint setWaypointTimeout (_attributes select 14);
	_newWaypoint setWaypointType (_attributes select 15);
	_newWaypoint setWaypointVisible (_attributes select 16);

	private _attachedVehicle = _attributes select 18;
	if (not isNull _attachedVehicle) then
	{
		_newWaypoint waypointAttachVehicle _attachedVehicle;
	};

	private _attachedObject = _attributes select 19;
	if (not isNull _attachedObject) then
	{
		_newWaypoint waypointAttachObject _attachedObject;
	};

	private _synchronizedWaypoints = _attributes select 17;
	if (count _synchronizedWaypoints > 0) then
	{
		_newWaypoint synchronizeWaypoint _synchronizedWaypoints;
	};

	_newWaypoint
};

OO_TRACE_DECL(SPM_ReinstatePatrolWaypoint) =
{
	params ["_waypoint"];

	private _attributes = [_waypoint] call SPM_PW_GetWaypointAttributes;

	private _group = _waypoint select 0;
	private _index = _waypoint select 1;

	deleteWaypoint _waypoint;

	[_group, _index, _attributes] call SPM_PW_CreateWaypointFromAttributes;
};

OO_TRACE_DECL(SPM_CopyPatrolWaypoints) =
{
	params ["_from", "_to"];

	{
		private _attributes = [_x] call SPM_PW_GetWaypointAttributes;
		[_to, -1, _attributes] call SPM_PW_CreateWaypointFromAttributes;
	} forEach waypoints _from;

	_to setCurrentWaypoint [_to, currentWaypoint _from];

	_to setVariable ["SPM_WaypointStatements", +(_from getVariable ["SPM_WaypointStatements", []])];
};

OO_TRACE_DECL(SPM_DeletePatrolWaypoints) =
{
	params ["_group"];

	private _waypoints = waypoints _group;
	if (count _waypoints > 0) then
	{
		(_waypoints select 0) setWaypointPosition [getPos leader _group, 0];

		for "_i" from (count _waypoints - 1) to 0 step -1 do
		{
			deleteWaypoint (_waypoints select _i);
		};
	};

	_group setVariable ["SPM_WaypointStatements", []];
};

OO_TRACE_DECL(SPM_StopWaypointMonitor) =
{
	params ["_group"];

	_group setVariable ["SPM_StopWaypointMonitor", true];
};

OO_TRACE_DECL(SPM_StartWaypointMonitor) =
{
	params ["_group"];

	_group setVariable ["SPM_StopWaypointMonitor", nil];

	[_group] spawn
	{
		params ["_group"];

		scriptName "SPM_StartWaypointMonitor";

		private _lastLeaderPosition = getPosATL leader _group;

		sleep 5;

		private _idleDistance = 2.0;
		private _shoveCount = 0;
		private _shoveWaypoint = -1;

		while { { alive _x } count units _group > 0 } do
		{
			private _stop = _group getVariable ["SPM_StopWaypointMonitor", false];
			if (_stop) exitWith { _group setVariable ["SPM_StopWaypointMonitor", nil] };

			private _leader = leader _group;

			if (alive _leader && { vehicle _leader == _leader } && { behaviour _leader in ["CARELESS", "SAFE", "AWARE"] } && { not captive _leader }) then
			{
				private _leaderPosition = getPosATL _leader;

				if (_leaderPosition distanceSqr _lastLeaderPosition < _idleDistance) then
				{
					private _waypointPosition = waypointPosition [_group, currentWaypoint _group];
					if (_leaderPosition distanceSqr _waypointPosition < _idleDistance) then
					{
						[_leader, _waypointPosition] call SPM_Util_SetPosition;
					}
					else
					{
						private _leaderDirection = direction _leader;
						[_leader, _leaderPosition vectorAdd [(sin _leaderDirection) * (_idleDistance + 0.2), (cos _leaderDirection) * (_idleDistance * 0.2), 0.0]] call SPM_Util_SetPosition;

						if (_shoveWaypoint != currentWaypoint _group) then
						{
							_shoveWaypoint = currentWaypoint _group;
							_shoveCount = 1;
						}
						else
						{
							_shoveCount = _shoveCount + 1;
							if (_shoveCount == 3) then
							{
								[_leader, _waypointPosition] call SPM_Util_SetPosition;
							};
						};
					};
				};

				_lastLeaderPosition = _leaderPosition;
			};

			sleep 2;
		};
	};
};

OO_TRACE_DECL(SPM_TaskComplete) =
{
	params ["_task"];

	if (_task select 1 == 0) then
	{
		_task set [1, 1];
	};

	private _taskCompletions = _task select 2;
	{
		[_task, _x select 1] call (_x select 0);
	} forEach _taskCompletions;
};

OO_TRACE_DECL(SPM_TaskOnComplete) =
{
	params ["_task", "_onCompletion", "_passthrough"];

	if (isNil "_passthrough") then { _passthrough = 0 };

	private _taskCompletions = _task select 2;
	_taskCompletions pushBack [_onCompletion, _passthrough];
};

OO_TRACE_DECL(SPM_TaskStop) =
{
	params ["_task"];

	_task set [1, -1];
};

OO_TRACE_DECL(SPM_TaskCreate) =
{
	params ["_object"];

	[_object, 0, [], []]
};

OO_TRACE_DECL(SPM_TaskGetState) =
{
	params ["_task"];

	_task select 1
};

OO_TRACE_DECL(SPM_TaskSetValue) =
{
	params ["_task", "_name", "_value"];

	private _values = _task select 3;

	private _index = [_values, _name] call BIS_fnc_findInPairs;
	if (_index == -1) then
	{
		_values pushback [_name, _value];
	}
	else
	{
		_values set [_index, [_name, _value]];
	};
};

OO_TRACE_DECL(SPM_TaskGetValue) =
{
	params ["_task", "_name", "_default"];

	private _values = _task select 3;

	private _index = [_values, _name] call BIS_fnc_findInPairs;
	if (_index == -1) exitWith { _default };

	(_values select _index) select 1
};

OO_TRACE_DECL(SPM_TaskGetObject) =
{
	params ["_task"];

	_task select 0
};

OO_TRACE_DECL(SPM_GoToNextBuilding) =
{
	params ["_leader", "_units", "_task"];

	private _patrolPositions = [_task, "PatrolPositions", []] call SPM_TaskGetValue;

	if (count _patrolPositions == 0 || { ([_task] call SPM_TaskGetState) == -1 }) exitWith
	{
		[_task] call SPM_TaskComplete;
	};

	{
		_x set [0, (_x select 1) distanceSqr (getpos _leader)];
	} forEach _patrolPositions;

	_patrolPositions sort true;

	_patrolPosition = _patrolPositions deleteAt 0;
	
	_waypoint = [_group, _patrolPosition select 1] call SPM_AddPatrolWaypoint;
	_waypoint setWaypointType "move";
	if (_patrolPosition select 3 >= 0) then
	{
		_waypoint setWaypointHousePosition (_patrolPosition select 3);
		_waypoint waypointAttachObject (_patrolPosition select 2);
	};
	[_waypoint, SPM_GoToNextBuilding, _task] call SPM_AddPatrolWaypointStatements;
};

OO_TRACE_DECL(SPM_PatrolBuildings) =
{
	params ["_group", "_buildings"]; // buildings: [[building-to-visit, should-enter], ...]

	private _task = [_group] call SPM_TaskCreate;

	private _index = 0;
	private _building = objNull;
	private _enter = false;

	private _patrolPositions = []; // [distance, position, building, buildingpos-index]

	for "_i" from (count _buildings - 1) to 0 step -1 do
	{
		_building = _buildings select _i select 0;
		_enter = _buildings select _i select 1;

		private _enteredBuilding = false;
		if (_enter && { not ([_building] call SPM_Occupy_BuildingIsOccupied) }) then
		{
			private _positions = _building buildingPos -1;
			if (count _positions > 0) then
			{
				_enteredBuilding = true;
				_index = floor random count _positions;
				_patrolPositions pushBack [0, _positions select _index, _building, _index];
			};
		};

		if (not _enteredBuilding) then
		{
			private _exits = [_building] call SPM_Occupy_GetBuildingExits;
			if (count _exits > 0) then
			{
				_patrolPositions pushBack [0, selectRandom _exits, _building, -1];
			};
		};
	};

	if (count _patrolPositions == 0) then
	{
		[_task] call SPM_TaskComplete;

		_task
	}
	else
	{
		[_group] call SPM_StartWaypointMonitor;
		[_task, { [[_this select 0] call SPM_TaskGetObject] call SPM_StopWaypointMonitor }] call SPM_TaskOnComplete;

		[_task, "PatrolPositions", _patrolPositions] call SPM_TaskSetValue;
		[leader _group, units _group, _task] call SPM_GoToNextBuilding;
	};

	_task
};

OO_TRACE_DECL(SPM_GoToNextRoadPosition) =
{
	params ["_leader", "_units", "_task"];

	private _group = group _leader;
	private _vehicle = objNull;
	{
		if (vehicle _x != _x) exitWith { _vehicle = vehicle _x };
	} forEach units _group;

	private _waypointPositions = [_task, "PatrolPositions", []] call SPM_TaskGetValue;
	if (count _waypointPositions == 0 || ([_task] call SPM_TaskGetState) == -1) exitWith
	{
		if (not isNull _vehicle) then
		{
			[_vehicle, -1] call JB_fnc_limitSpeed;
		};

		[_task] call SPM_TaskComplete;
	};

	if (not isNull _vehicle) then
	{
		[_vehicle, 15] call JB_fnc_limitSpeed;

		private _shouldBeDismounted = random 1 < 0.4;

		if (_shouldBeDismounted) then
		{
			private _dismounts = (fullCrew _vehicle) select { (_x select 1) == "cargo" || ((_x select 1) == "Turret" && (_x select 4)) };

			if (count _dismounts > 0) then
			{
				private _waypoint = [_group, getPos _vehicle] call SPM_AddPatrolWaypoint;
				_waypoint setWaypointType "unload";
			};
		}
		else
		{
			private _dismounts = units _group select { vehicle _x == _x };
			if (count _dismounts > 0) then
			{
				private _waypoint = [_group, getPos _vehicle] call SPM_AddPatrolWaypoint;
				_waypoint waypointAttachVehicle _vehicle;
				_waypoint setWaypointType "load";
			};
		};
	};

	private _waypointPosition = _waypointPositions deleteAt 0;

	private _waypoint = [_group, _waypointPosition] call SPM_AddPatrolWaypoint;
	_waypoint setWaypointType "move";
	[_waypoint, SPM_GoToNextRoadPosition, _task] call SPM_AddPatrolWaypointStatements;
};

OO_TRACE_DECL(SPM_PatrolRoads) =
{
	params ["_group", "_position", "_radius"];

//	diag_log "SPM_PatrolRoads";

	private _task = [_group] call SPM_TaskCreate;

	private _vehicle = vehicle leader _group;
	private _intersections = [_position, _radius] call SPM_Nav_GetIntersections;

//	diag_log format ["SPM_PatrolRoads: intersections: %1", count _intersections];

	if (count _intersections == 0) exitWith
	{
		[_task] call SPM_TaskComplete;

		_task
	};

	private _from = [_intersections, getPos _vehicle, vectorDir _vehicle] call SPM_Nav_GetIntersectionInFront;
	private _to = [_intersections, (_intersections select _from) select 0, vectorDir _vehicle] call SPM_Nav_GetIntersectionInFront;

//	diag_log format ["SPM_WS_PatrolRoads: intersection from-to: %1-%2", _from, _to];

	private _visits = _intersections apply { 0 };

	private _waypointPositions = [];

	for "_i" from 0 to count _intersections - 1 do
	{
		private _intersection = _intersections select _to;
		private _waypointPosition = _intersection select 0;
		_waypointPosition set [2, 1];

		if (count _waypointPositions == 0 || { _waypointPosition distanceSqr (_waypointPositions select (count _waypointPositions - 1)) > (15 * 15) }) then
		{
			_waypointPositions pushBack _waypointPosition;
		};

		private _choices = [];
		{
			if (_x != _from) then { _choices pushBack _x };
		} forEach (_intersection select 1);

		_from = _to;

		private _minVisits = 1e30;
		private _minVisitsIndex = -1;
		{
			if (_visits select _x < _minVisits) then
			{
				_minVisits = _visits select _x;
				_minVisitsIndex = _x;
			};
		} forEach _choices;

		_to = _minVisitsIndex;

		_visits set [_to, (_visits select _to) + 1];
	};

	if (count _waypointPositions == 0) then
	{
		[_task] call SPM_TaskComplete;
	}
	else
	{
		[_task, "PatrolPositions", _waypointPositions] call SPM_TaskSetValue;
		[leader _group, units _group, _task] call SPM_GoToNextRoadPosition;
	};

	_task
};
