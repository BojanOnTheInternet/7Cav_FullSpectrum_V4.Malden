/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_MortarUnit_CanExecuteFireMission) =
{
	params ["_mortarUnit", "_fireMission"];

	private _mortar = OO_GET(_mortarUnit,MortarUnit,Mortar);

	if (not canFire _mortar) exitWith { false };

	if (count OO_GET(_mortarUnit,MortarUnit,_FireMission) > 0) exitWith { false };

	private _requiredAmmunition = [] call OO_METHOD(_fireMission,MortarFireMission,GetRequiredAmmunition);

	private _readyToShoot = true;
	{
		private _roundType = _x select 0;
		private _roundsNeeded = _x select 1;

		private _magazines = (magazinesAmmo _mortar) select { _x select 0 == _roundType };
		private _roundsAvailable = 0;
		{ _roundsAvailable = _roundsAvailable + (_x select 1) } forEach _magazines;

		if (_roundsAvailable < _roundsNeeded) exitWith { _readyToShoot = false };
	} forEach _requiredAmmunition;

	_readyToShoot
};

OO_TRACE_DECL(SPM_MortarUnit_ExecuteFireMission) =
{
	params ["_mortarUnit", "_fireMission"];

	OO_SET(_mortarUnit,MortarUnit,_FireMission,_fireMission);

	[_mortarUnit] spawn
	{
		params ["_mortarUnit"];

		scriptName "SPM_MortarUnit_ExecuteFireMission";

		private _mortar = OO_GET(_mortarUnit,MortarUnit,Mortar);

		private _fireMission = OO_GET(_mortarUnit,MortarUnit,_FireMission);
		private _targetPosition = OO_GET(_fireMission,MortarFireMission,TargetPosition);
		private _sequence = OO_GET(_fireMission,MortarFireMission,Sequence);

		for "_i" from 0 to (count _sequence - 1) do
		{
			private _step = _sequence select _i;
			sleep (_step select 0);
			if (_step select 1 != "") then { _mortar doArtilleryFire [_targetPosition, _step select 1, 1] };
		};

		OO_SET(_mortarUnit,MortarUnit,_FireMission,[]);
	};
};

OO_TRACE_DECL(SPM_MortarUnit_Create) =
{
	params ["_mortarUnit", "_mortar", "_crew"];

	OO_SET(_mortarUnit,MortarUnit,Mortar,_mortar);
	OO_SET(_mortarUnit,MortarUnit,Crew,_crew);
};

OO_BEGIN_STRUCT(MortarUnit);
	OO_OVERRIDE_METHOD(MortarUnit,RootStruct,Create,SPM_MortarUnit_Create);
	OO_DEFINE_METHOD(MortarUnit,CanExecuteFireMission,SPM_MortarUnit_CanExecuteFireMission);
	OO_DEFINE_METHOD(MortarUnit,ExecuteFireMission,SPM_MortarUnit_ExecuteFireMission);
	OO_DEFINE_PROPERTY(MortarUnit,Mortar,"OBJECT",objNull);
	OO_DEFINE_PROPERTY(MortarUnit,Crew,"GROUP",grpNull);
	OO_DEFINE_PROPERTY(MortarUnit,_FireMission,"ARRAY",[]);
OO_END_STRUCT(MortarUnit);

OO_TRACE_DECL(SPM_MortarFireMission_Create) =
{
	params ["_fireMission", "_targetPosition", "_sequence"];

	OO_SET(_fireMission,MortarFireMission,TargetPosition,_targetPosition);
	OO_SET(_fireMission,MortarFireMission,Sequence,_sequence);
};

OO_TRACE_DECL(SPM_MortarFireMission_GetRequiredAmmunition) =
{
	params ["_fireMission"];

	private _ammunition = []; // Array of [round-type, count] pairs

	{
		private _index = [_ammunition, _x select 1] call BIS_fnc_findInPairs;
		if (_index == -1) then
		{
			_ammunition pushBack [_x select 1, 1];
		}
		else
		{
			private _round = _ammunition select _index;
			_round set [1, (_round select 1) + 1];
		};
	} forEach OO_GET(_fireMission,MortarFireMission,Sequence);

	_ammunition
};

OO_BEGIN_STRUCT(MortarFireMission);
	OO_OVERRIDE_METHOD(MortarFireMission,RootStruct,Create,SPM_MortarFireMission_Create);
	OO_DEFINE_METHOD(MortarFireMission,GetRequiredAmmunition,SPM_MortarFireMission_GetRequiredAmmunition);
	OO_DEFINE_PROPERTY(MortarFireMission,TargetPosition,"ARRAY",[]);
	OO_DEFINE_PROPERTY(MortarFireMission,Sequence,"ARRAY",[]); // Array of [delay, round-type] pairs
OO_END_STRUCT(MortarFireMission);

OO_TRACE_DECL(SPM_Mortar_AddFireMission) =
{
	params ["_category", "_fireMission"];

	OO_GET(_category,MortarCategory,_FireMissions) pushBack _fireMission;
};

OO_TRACE_DECL(SPM_Mortar_CanExecuteFireMission) =
{
	params ["_category", "_fireMission"];

	count OO_GET(_category,MortarCategory,_FireMissions) < { [_fireMission] call OO_METHOD(_x,MortarUnit,CanExecuteFireMission) } count OO_GET(_category,MortarCategory,_MortarUnits);
};

OO_TRACE_DECL(SPM_Mortar_Create) =
{
	params ["_category", "_number", "_garrison"];

	OO_SET(_category,Category,GetUpdateInterval,{30});
	OO_SET(_category,MortarCategory,Number,_number);
	OO_SETREF(_category,MortarCategory,Garrison,_garrison);
};

OO_TRACE_DECL(SPM_Mortar_Delete) =
{
	params ["_category"];

	private _garrison = OO_GETREF(_category,MortarCategory,Garrison);
	private _mortarUnits = OO_GET(_category,MortarCategory,_MortarUnits);
	while { count _mortarUnits > 0 } do
	{
		private _mortarUnit = _mortarUnits deleteAt 0;
		private _mortar = OO_GET(_mortarUnit,MortarUnit,Mortar);

		if (not isNull _mortar) then
		{
			private _gunner = gunner _mortar;
			if (not isNull _gunner) then
			{
				unassignVehicle _gunner;
				[_gunner] allowGetIn false;
				[_gunner] orderGetIn false;
				_gunner enableAI "autotarget";
				_gunner enableAI "target";
			};
			deleteVehicle _mortar;
		};

		[OO_GET(_mortarUnit,MortarUnit,Crew)] call OO_METHOD(_garrison,InfantryGarrisonCategory,EndTemporaryDuty);
	};

	// Put back the objects we hid to make room for the mortars
	{
		_x hideObjectGlobal false;
	} forEach OO_GET(_category,MortarCategory,_BlockingObjects);
};

OO_TRACE_DECL(SPM_Mortar_GetMortarRadius) =
{
	params ["_number"];

	if (_number == 1) then { 0 } else { 2.0 + ((_number * 4.0) / (2 * pi)) } // Circle with 4 meters of circumference devoted to each mortar unit
};

OO_TRACE_DECL(SPM_Mortar_CreateClearing) =
{
	params ["_category", "_center"];

	private _innerRadius = 0;
	private _outerRadius = 40;
	private _unitRadius = 2;

	private _positions = [];
	private _idealPositions = [];
	while { _innerRadius <= _outerRadius } do
	{
		_positions = [_center, _innerRadius, _innerRadius + 20, 4.0] call SPM_Util_SampleAreaGrid;
		[_positions, ["#GdtRoad", "#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
		[_positions, 10, 90] call SPM_Util_ExcludeSamplesBySurfaceIncline;
		[_positions, _unitRadius, ["WALL", "ROCK", "ROAD"]] call SPM_Util_ExcludeSamplesByProximity;  // Exclude shorter objects
		[_positions, _unitRadius + 4.0, ["BUILDING", "HOUSE"]] call SPM_Util_ExcludeSamplesByProximity; // Exclude taller objects
		[_positions, _unitRadius + 10.0, ["WALL", "BUILDING", "HOUSE", "ROCK", "ROAD"], _idealPositions] call SPM_Util_ExcludeSamplesByProximity; // Want to stay near to some cover

		if (count _idealPositions > 0) then { _positions = _idealPositions };

		if (count _positions > 0) exitWith { };

		diag_log format ["SPM_Mortar_CreateClearing: Unable to find clearing %1, %2, %3", _center, _innerRadius, _innerRadius + 20];
		_innerRadius = _innerRadius + 20;
	};

	if (count _positions == 0) exitWith { [] };

	private _clearingPosition = [_positions, _center] call SPM_Util_ClosestPosition;

	private _blockingObjects = nearestTerrainObjects [_clearingPosition, ["TREE", "SMALL TREE", "BUSH", "HIDE", "FENCE"], 10, false, true];
	{
		_x hideObjectGlobal true;
	} forEach _blockingObjects;

	OO_GET(_category,MortarCategory,_BlockingObjects) append _blockingObjects;

	_clearingPosition
};

OO_TRACE_DECL(SPM_Mortar_WS_CrewArrived) =
{
	params ["_leader", "_units", "_mortarUnit"];

	private _mortar = OO_GET(_mortarUnit,MortarUnit,Mortar);

	private _waypoint = [group _leader, getPos _mortar] call SPM_AddPatrolWaypoint;
	_waypoint setWaypointType "hold";
	_waypoint setWaypointFormation "diamond";

	if (alive _mortar) then
	{
		_leader assignAsGunner _mortar;
		[_leader] orderGetIn true;
		_leader disableAI "autotarget";
		_leader disableAI "target";
	};
};

OO_TRACE_DECL(SPM_Mortar_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,Category);

	private _mortarUnits = OO_GET(_category,MortarCategory,_MortarUnits);
	private _number = OO_GET(_category,MortarCategory,Number);

	if (count _mortarUnits < _number) then
	{
		private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
		private _garrison = OO_GETREF(_category,MortarCategory,Garrison);
		private _mortarType = OO_GET(_category,MortarCategory,MortarType);

		private _failedGroups = [];

		for "_i" from count _mortarUnits to _number - 1 do
		{
			private _position = [];
			private _group = [OO_GET(_category,MortarCategory,TeamSize)] call OO_METHOD(_garrison,InfantryGarrisonCategory,BeginTemporaryDuty);

			if (not isNull _group) then
			{
				if (not isNull leader _group) then
				{
					_position = [_category, getPos leader _group] call SPM_Mortar_CreateClearing;
				};

				if (count _position == 0) then
				{
					_failedGroups pushBack _group;
				}
				else
				{
					private _mortar = [_mortarType, _position, 0, ""] call SPM_fnc_spawnVehicle;
					[_category, _mortar] call OO_GET(_category,Category,InitializeObject);

					private _mortarUnit = [_mortar, _group] call OO_CREATE(MortarUnit);

					_mortarUnits pushBack _mortarUnit;

					private _waypoint = [_group, _position] call SPM_AddPatrolWaypoint;
					[_waypoint, SPM_Mortar_WS_CrewArrived, _mortarUnit] call SPM_AddPatrolWaypointStatements;

					// If the first update of the strongpoint, move the units to the first waypoint
					if (OO_GET(_strongpoint,Strongpoint,UpdateIndex) == 1) then
					{
						private _waypointPosition = waypointPosition [_group, currentWaypoint _group];
						{ _x setPos _waypointPosition } forEach units _group;
					};
				};
			};
		};

		{
			[_x] call OO_METHOD(_garrison,InfantryGarrisonCategory,EndTemporaryDuty);
		} forEach _failedGroups;
	};

	private _fireMissions = OO_GET(_category,MortarCategory,_FireMissions);

	while { count _fireMissions > 0 } do
	{
		private _fireMission = _fireMissions deleteAt 0;
		{
			if ([_fireMission] call OO_METHOD(_x,MortarUnit,CanExecuteFireMission)) exitWith { [_fireMission] call OO_METHOD(_x,MortarUnit,ExecuteFireMission) }
		} forEach OO_GET(_category,MortarCategory,_MortarUnits);
	};
};

OO_BEGIN_SUBCLASS(MortarCategory,Category);
	OO_OVERRIDE_METHOD(MortarCategory,Root,Create,SPM_Mortar_Create);
	OO_OVERRIDE_METHOD(MortarCategory,Root,Delete,SPM_Mortar_Delete);
	OO_OVERRIDE_METHOD(MortarCategory,Category,Update,SPM_Mortar_Update);
	OO_DEFINE_METHOD(MortarCategory,CanExecuteFireMission,SPM_Mortar_CanExecuteFireMission);
	OO_DEFINE_METHOD(MortarCategory,AddFireMission,SPM_Mortar_AddFireMission);
	OO_DEFINE_PROPERTY(MortarCategory,Number,"SCALAR",0);
	OO_DEFINE_PROPERTY(MortarCategory,TeamSize,"SCALAR",4);
	OO_DEFINE_PROPERTY(MortarCategory,MortarType,"STRING","O_Mortar_01_F");
	OO_DEFINE_PROPERTY(MortarCategory,Garrison,"#REF",OO_NULL);
	OO_DEFINE_PROPERTY(MortarCategory,_FireMissions,"ARRAY",[]);
	OO_DEFINE_PROPERTY(MortarCategory,_MortarUnits,"ARRAY",[]);
	OO_DEFINE_PROPERTY(MortarCategory,_BlockingObjects,"ARRAY",[]);
OO_END_SUBCLASS(MortarCategory);
