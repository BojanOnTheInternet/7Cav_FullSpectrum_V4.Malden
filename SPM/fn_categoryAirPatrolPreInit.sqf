/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

#define CALLUP_DISTANCE 7500
#define RETIRE_DISTANCE 7500

#ifdef TEST
#define CALLUP_INTERVAL [10,10]
#else
#define CALLUP_INTERVAL [720,1020]
#endif

OO_BEGIN_STRUCT(Airfield);
	OO_DEFINE_PROPERTY(Airfield,Name,"STRING","");
	OO_DEFINE_PROPERTY(Airfield,Position,"ARRAY",[]);
	OO_DEFINE_PROPERTY(Airfield,Radius,"SCALAR",0);
	OO_DEFINE_PROPERTY(Airfield,SpawnPosition,"ARRAY",[]);
	OO_DEFINE_PROPERTY(Airfield,SpawnDirection,"SCALAR",0);
	OO_DEFINE_PROPERTY(Airfield,Functional,"BOOL",false);
OO_END_STRUCT(Airfield);

SPM_AirPatrol_Airfields = [];

switch (toLower worldName) do
{
	case "altis":
	{
		private _position = [];
		private _spawnPosition = [];
		private _airfield = OO_NULL;

		_position = [09110, 21510, 0];
		_spawnPosition = [09150, 21480, 0];
		_airfield = [] call OO_CREATE(Airfield);
		OO_SET(_airfield,Airfield,Name,"Krya Nera Airfield");
		OO_SET(_airfield,Airfield,Position,_position);
		OO_SET(_airfield,Airfield,Radius,300);
		OO_SET(_airfield,Airfield,SpawnPosition,_spawnPosition);
		OO_SET(_airfield,Airfield,SpawnDirection,54);
		OO_SET(_airfield,Airfield,Functional,false);

		SPM_AirPatrol_Airfields pushBack _airfield;

		_position = [11490, 11720, 0];
		_spawnPosition = [11360, 11440, 0];
		_airfield = [] call OO_CREATE(Airfield);
		OO_SET(_airfield,Airfield,Name,"AAC Airfield");
		OO_SET(_airfield,Airfield,Position,_position);
		OO_SET(_airfield,Airfield,Radius,400);
		OO_SET(_airfield,Airfield,SpawnPosition,_spawnPosition);
		OO_SET(_airfield,Airfield,SpawnDirection,35);
		OO_SET(_airfield,Airfield,Functional,true);

		SPM_AirPatrol_Airfields pushBack _airfield;

		_position = [20990, 07270, 0];
		_spawnPosition = [21120, 07330, 0];
		_airfield = [] call OO_CREATE(Airfield);
		OO_SET(_airfield,Airfield,Name,"Selakano Airfield");
		OO_SET(_airfield,Airfield,Position,_position);
		OO_SET(_airfield,Airfield,Radius,400);
		OO_SET(_airfield,Airfield,SpawnPosition,_spawnPosition);
		OO_SET(_airfield,Airfield,SpawnDirection,10);
		OO_SET(_airfield,Airfield,Functional,false);

		SPM_AirPatrol_Airfields pushBack _airfield;

		_position = [26920, 24730, 0];
		_spawnPosition = [27150, 24900, 0];
		_airfield = [] call OO_CREATE(Airfield);
		OO_SET(_airfield,Airfield,Name,"Molos Airfield");
		OO_SET(_airfield,Airfield,Position,_position);
		OO_SET(_airfield,Airfield,Radius,400);
		OO_SET(_airfield,Airfield,SpawnPosition,_spawnPosition);
		OO_SET(_airfield,Airfield,SpawnDirection,235);
		OO_SET(_airfield,Airfield,Functional,true);

		SPM_AirPatrol_Airfields pushBack _airfield;

		_position = [14720, 16590, 0];
		_spawnPosition = [14360, 15900, 0];
		_airfield = [] call OO_CREATE(Airfield);
		OO_SET(_airfield,Airfield,Name,"Altis International Airport");
		OO_SET(_airfield,Airfield,Position,_position);
		OO_SET(_airfield,Airfield,Radius,1200);
		OO_SET(_airfield,Airfield,SpawnPosition,_spawnPosition);
		OO_SET(_airfield,Airfield,SpawnDirection,40);
		OO_SET(_airfield,Airfield,Functional,true);

		SPM_AirPatrol_Airfields pushBack _airfield;
	};
};

OO_TRACE_DECL(SPM_Chain_NearestAirfield) =
{
	params ["_data", "_direction", "_reference", "_allAirfields"];

	private _remainingAirfields = [_data, "remaining-airfields"] call SPM_Util_GetDataValue;

	if (isNil "_remainingAirfields") then
	{
		_remainingAirfields = _allAirfields apply { [_reference distance2D OO_GET(_x,Airfield,Position), _x] } ;
		_remainingAirfields sort true;
		[_data, "remaining-airfields", _remainingAirfields] call SPM_Util_SetDataValue;
	};

	if (count _remainingAirfields == 0) exitWith { false };

	private _airfield = (_remainingAirfields deleteAt 0) select 1;
	private _position = OO_GET(_airfield,Airfield,Position);

	[_data, "airfield", _airfield] call SPM_Util_SetDataValue;
	[_data, "position", _position] call SPM_Util_SetDataValue;

	true
};

OO_TRACE_DECL(SPM_WS_SalvageAirPatrol) =
{
	params ["_leader", "_units", "_category"];

	[_category, group _leader] call SPM_Force_SalvageForceUnit;
};

OO_TRACE_DECL(SPM_AirPatrol_Retire) =
{
	params ["_forceUnitIndex", "_category"];

	private _forceUnit = OO_GET(_category,ForceCategory,ForceUnits) select _forceUnitIndex;

	// If already retiring, return
	if ([_forceUnit] call SPM_Force_IsRetiring) exitWith {};

	private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);
	private _position = _vehicle getVariable "SPM_AirPatrol_RetirePosition";
	private _group = [] call OO_METHOD(_forceUnit,ForceUnit,GetGroup);

	[_group] call SPM_DeletePatrolWaypoints;

	[units _group] call SPM_Util_AIOnlyMove;

	private _waypoint = [_group, _position] call SPM_AddPatrolWaypoint;
	[_waypoint, SPM_WS_SalvageAirPatrol, _category] call SPM_AddPatrolWaypointStatements;

	[_forceUnit, true] call SPM_Force_SetRetiring;
};

OO_TRACE_DECL(SPM_AirPatrol_Reinstate) =
{
	params ["_forceUnitIndex", "_category"];

	private _forceUnit = OO_GET(_category,ForceCategory,ForceUnits) select _forceUnitIndex;
	private _group = [] call OO_METHOD(_forceUnit,ForceUnit,GetGroup);

	[_group] call SPM_DeletePatrolWaypoints;

	[units _group] call SPM_Util_AIFullCapability;

	[_forceUnit, false] call SPM_Force_SetRetiring;
	[_category, _group] call SPM_AirPatrol_Task_Patrol;
};

OO_TRACE_DECL(SPM_AirPatrol_WS_TargetDestroyed) =
{
	params ["_leader", "_units", "_category"];

	[_category, group _leader] call SPM_AirPatrol_Task_Patrol;
};

OO_TRACE_DECL(SPM_AirPatrol_TC_Patrol) =
{
	params ["_task", "_category"];

	private _group = [_task] call SPM_TaskGetObject;

	[_category, _group] call SPM_AirPatrol_Task_Patrol;
};

OO_TRACE_DECL(SPM_AirPatrol_Task_Patrol) =
{
	params ["_category", "_patrolGroup"];

	switch (OO_GET(_category,AirPatrolCategory,PatrolType)) do
	{
		case "area":
		{
			private _area = OO_GET(_category,ForceCategory,Area);

			private _minRadius = OO_GET(_area,StrongpointArea,InnerRadius);
			private _maxRadius = OO_GET(_area,StrongpointArea,OuterRadius);
			private _circumference = 2 * pi * ((_minRadius + _maxRadius) / 2.0);

			_task = [_patrolGroup, OO_GET(_area,StrongpointArea,Position), _minRadius, _maxRadius, random 1 < 0.5, _circumference * 0.2, _circumference * 0.4, 0, 0, 0] call SPM_fnc_patrolPerimeter;
			[_task, SPM_AirPatrol_TC_Patrol, _category] call SPM_TaskOnComplete;
		};
		
		case "target":
		{
			private _westForce = [OO_GET(_category,ForceCategory,RangeWest)] call OO_METHOD(_category,ForceCategory,GetForceLevelsWest);
			_westForce = _westForce select { not isTouchingGround OO_GET(_x,ForceRating,Vehicle) };

			if (count _westForce > 0) then
			{
				private _targetForce = selectRandom _westForce;
				private _targetVehicle = OO_GET(_targetForce,ForceUnit,Vehicle);

				private _waypoint = [_patrolGroup, getPos _targetVehicle] call SPM_AddPatrolWaypoint;
				_waypoint waypointAttachVehicle _targetVehicle;
				_waypoint setWaypointType "destroy";
				[_waypoint, SPM_AirPatrol_WS_TargetDestroyed, _category] call SPM_AddPatrolWaypointStatements;
			};
		};
	};
};

// Only shoot at armed aircraft
OO_TRACE_DECL(SPM_AirPatrol_RestrictTargeting) =
{
	_this spawn
	{
		params ["_vehicle"];

		scriptName "SPM_AirPatrol_RestrictTargeting";

		private _target = objNull;
		private _baseAreas = [0, -1, -1] call SERVER_OperationBlacklist;

		while { alive _vehicle } do
		{
			{
				_target = _x;

				// If the engine isn't on, or if it's not an aircraft, or it's on a base, forget it
				if (not isEngineOn _vehicle || { not ((vehicle _target) isKindOf "Air") } || { _baseAreas findIf { [getPos _target, _x] call SPM_Util_PositionInArea } >= 0 }) then
				{
					_vehicle forgetTarget _target;
				};
			} forEach (effectiveCommander _vehicle targets [true]);

			sleep 0.5;
		};
	};
};

OO_TRACE_DECL(SPM_AirPatrol_CreateUnit) =
{
	params ["_category", "_position", "_direction", "_type"];

	private _index = OO_GET(_category,ForceCategory,CallupsEast) findIf { _x select 0 == _type };
	if (_index == -1) exitWith {};
	private _vehicleDescriptor = OO_GET(_category,ForceCategory,CallupsEast) select _index select 1;

	private _unitVehicle = [_type, _position, _direction, "fly"] call SPM_fnc_spawnVehicle;

	private _retirePosition = _position vectorAdd [-500 + random 1000, -500 + random 1000, 0];
	_retirePosition set [2, (_retirePosition select 2) max (500 + random 500)];
	_unitVehicle setVariable ["SPM_AirPatrol_RetirePosition", _retirePosition];

	private _crew = [_unitVehicle] call SPM_fnc_groupFromVehicleCrew;
	private _crewSide = _crew select 0;
	private _crewDescriptor = _crew select 1;

	_crewDescriptor = [[_unitVehicle]] + _crewDescriptor;

	private _unitGroup = [_crewSide, _crewDescriptor, [_unitVehicle, 0.0] call SPM_PositionInFrontOfVehicle, 0, true] call SPM_fnc_spawnGroup;

	[_unitVehicle] call (_vehicleDescriptor select 3);
	[_category, _unitGroup] call OO_GET(_category,Category,InitializeObject);
	[_category, _unitVehicle] call OO_GET(_category,Category,InitializeObject);

	if (_unitVehicle isKindOf "Plane") then
	{
		_unitVehicle addEventHandler ["GetOut",
			{
				params ["_vehicle", "_position", "_unit"];

				deleteVehicle vehicle _unit; // Ejection seat
				deleteVehicle _unit; // Crewman
			}];
	};

	[_unitVehicle] call SPM_AirPatrol_RestrictTargeting;
	[_category, _unitGroup] call SPM_AirPatrol_Task_Patrol;

	private _forceUnit = [_unitVehicle, units _unitGroup] call OO_CREATE(ForceUnit);

	OO_GET(_category,ForceCategory,ForceUnits) pushBack _forceUnit;
	private _forceRatings = [OO_GET(_forceUnit,ForceUnit,Units), OO_GET(_category,ForceCategory,RatingsEast)] call SPM_Force_GetForceRatings;

	if (count _forceRatings == 0) then
	{
		diag_log format ["SPM_AirPatrol_CreateUnit: no force rating available for %1.  Created unit not charged against category reserves.", _type];
	}
	else
	{
		private _reserves = OO_GET(_category,ForceCategory,Reserves) - OO_GET(_forceRatings select 0,ForceRating,Rating);
		OO_SET(_category,ForceCategory,Reserves,_reserves);
	};

	_forceUnit
};

OO_TRACE_DECL(SPM_AirPatrol_CallUp) =
{
	params ["_position", "_direction", "_category", "_type"];

	if (OO_GET(_category,ForceCategory,_Surrendered)) exitWith {};

	private _forceUnit = [_category, _position, _direction, _type] call SPM_AirPatrol_CreateUnit;

	sleep 5;

	if (not alive OO_GET(_forceUnit,ForceUnit,Vehicle) || { _position distance OO_GET(_forceUnit,ForceUnit,Vehicle) < 10 }) exitWith
	{
		[_category, _forceUnit] call SPM_Force_SalvageForceUnit;
	};
};

OO_TRACE_DECL(SPM_AirPatrol_CreateAirfieldStrongpoint) =
{
	params ["_category"];

	private _area = OO_GET(_category,ForceCategory,Area);
	private _center = OO_GET(_area,StrongpointArea,Position);

	private _data = [];
	private _chain =
		[
			[SPM_Chain_NearestAirfield, [_center, SPM_AirPatrol_Airfields]],
			[SPM_Chain_PositionToIsolatedPosition, [[4500, 4500, -1] call SERVER_OperationBlacklist]]
		];
	private _complete = [_data, _chain] call SPM_Chain_Execute;

	_airfield = [_data, "airfield"] call SPM_Util_GetDataValue;

	private _airfieldPosition = OO_GET(_airfield,Airfield,Position);
	private _airfieldRadius = OO_GET(_airfield,Airfield,Radius);

	private _airfieldStrongpoint = [_airfieldPosition, _airfieldRadius, _airfieldRadius] call OO_CREATE(Strongpoint);
	OO_SET(_airfieldStrongpoint,Strongpoint,Name,"Air Patrol Airfield Air Defense");

	private _area = [_airfieldPosition, 0, _airfieldRadius] call OO_CREATE(StrongpointArea);
	private _airDefense = [_area] call OO_CREATE(AirDefenseCategory);
	OO_SET(_airDefense,ForceCategory,RatingsWest,SPM_AirDefense_RatingsWest);
	OO_SET(_airDefense,ForceCategory,RatingsEast,SPM_AirDefense_RatingsEast);
	OO_SET(_airDefense,ForceCategory,CallupsEast,SPM_AirDefense_CallupsEast);
	OO_SET(_airDefense,ForceCategory,RangeWest,10000);
	[_airDefense] call OO_METHOD(_airfieldStrongpoint,Strongpoint,AddCategory);

	OO_SET(_category,AirPatrolCategory,Airfield,_airfield);
	OO_SET(_category,AirPatrolCategory,AirfieldStrongpoint,_airfieldStrongpoint);
	OO_SET(_category,AirPatrolCategory,AirfieldAirDefense,_airDefense);
};

#define SPAWN_DISTANCE 2000
SPM_AirPatrol_SpawnBounds = [[worldSize / 2 - SPAWN_DISTANCE, worldSize / 2 - SPAWN_DISTANCE, 0], worldSize / 2 + SPAWN_DISTANCE, worldSize / 2 + SPAWN_DISTANCE, 0, true];

OO_TRACE_DECL(SPM_AirPatrol_MapExit) =
{
	params ["_position", "_direction", "_area"];

	_direction = _direction vectorMultiply 1000;

	while { count ([_position] inAreaArray _area) > 0 } do
	{
		_position = _position vectorAdd _direction;
	};

	_position
};

OO_TRACE_DECL(SPM_AirPatrol_Update)	 =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,ForceCategory);

	[OO_GET(_category,ForceCategory,ForceUnits), { not alive OO_GET(_x,ForceUnit,Vehicle) }] call SPM_Force_DeleteForceUnits;

	if (OO_GET(_category,ForceCategory,_Surrendered)) exitWith {};

	private _westForce = [OO_GET(_category,ForceCategory,RangeWest)] call OO_METHOD(_category,ForceCategory,GetForceLevelsWest);
	private _eastForce = [-1] call OO_METHOD(_category,ForceCategory,GetForceLevelsEast);

	_westForce = _westForce select { not isTouchingGround OO_GET(_x,ForceRating,Vehicle) };

	private _changes = [_category, _westForce, _eastForce] call SPM_Force_Rebalance;

	private _units = OO_GET(_category,ForceCategory,ForceUnits);
	{
		[[_units, { OO_GET(_this select 0,ForceUnit,Vehicle) == (_this select 1) }, _x] call SPM_Util_Find, _category] call SPM_AirPatrol_Retire;
	} forEach CHANGES(_changes,retire);
	{
		[[_units, { OO_GET(_this select 0,ForceUnit,Vehicle) == (_this select 1) }, _x] call SPM_Util_Find, _category] call SPM_AirPatrol_Reinstate;
	} forEach CHANGES(_changes,reinstate);

	// Callups only every CALLUP_INTERVAL
	private _callupTime = OO_GET(_category,AirPatrolCategory,_CallupTime);

	if (diag_tickTime < _callupTime) exitWith {};

	private _callupInterval = OO_GET(_category,AirPatrolCategory,CallupInterval);
	private _callupTime = diag_tickTime + (_callupInterval select 0) + (random ((_callupInterval select 1) - (_callupInterval select 0)));
	OO_SET(_category,AirPatrolCategory,_CallupTime,_callupTime);

	if (count CHANGES(_changes,callup) > 0) then
	{
		private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
		private _spawnManager = OO_GET(_strongpoint,Strongpoint,SpawnManager);

#ifdef USE_EXISTING_AIRFIELD
		private _airfieldStrongpoint = OO_GET(_category,AirPatrolCategory,AirfieldStrongpoint);

		if (OO_ISNULL(_airfieldStrongpoint)) then
		{
			[_category] call SPM_AirPatrol_CreateAirfieldStrongpoint;

			_airfieldStrongpoint = OO_GET(_category,AirPatrolCategory,AirfieldStrongpoint);

			[_airfieldStrongpoint] spawn { params ["_airfieldStrongpoint"]; scriptName "SPM_AirPatrol_AirfieldRun"; [] call OO_METHOD(_airfieldStrongpoint,Strongpoint,Run) }; // Cannot spawn OO_METHODs
		};

		private _airfield = OO_GET(_category,AirPatrolCategory,Airfield);

		private _position = OO_GET(_airfield,Airfield,SpawnPosition);
		private _direction = OO_GET(_airfield,Airfield,SpawnDirection);

//		if (not OO_GET(_airfield,Airfield,Functional)) then { _position set [2, 100] };
		_position set [2, 10]; // Keep the aircraft off the ground to allow for wreckage on the runway

		{
			[_position, _direction, SPM_AirPatrol_CallUp, [_category, _x select 0]] call OO_METHOD(_spawnManager,SpawnManager,ScheduleSpawn);
		} forEach CHANGES(_changes,callup);

		private _airDefense = OO_GET(_category,AirPatrolCategory,AirfieldAirDefense);
		[_position] call OO_METHOD(_airDefense,AirDefenseCategory,RequestSupport);
#else
		private _baseAreas = [0, -1, -1] call SERVER_OperationBlacklist;
		{
			private _target = OO_GET(selectRandom _westForce,ForceRating,Vehicle);

			// Compute a vector that points at the target from the various bases.  That's the direction we want to spawn the attacking aircraft.
			private _vector = [0,0,0]; { _vector = _vector vectorAdd ((_x select 1) vectorFromTo getPos _target) } forEach _baseAreas;

			// But we also want to randomize that direction a bit, so add +/- 45 degrees
			private _direction = [0,0,0] getDir _vector;
			_direction = _direction - 45 + random 90;
			_vector = [sin _direction, cos _direction, 0];

			// Find where we end up by starting at the target and following the vector until we're outside the limits of SPM_AirPatrol_SpawnBounds
			private _position = [getPos _target, _vector, SPM_AirPatrol_SpawnBounds] call SPM_AirPatrol_MapExit;

			// Spawn in high up
			_position set [2, 5000];

			// Be pointed at our target
			_direction = _position getDir _target;

			[_position, _direction, SPM_AirPatrol_CallUp, [_category, _x select 0]] call OO_METHOD(_spawnManager,SpawnManager,ScheduleSpawn);
		} forEach CHANGES(_changes,callup);
#endif
	};
};

OO_TRACE_DECL(SPM_AirPatrol_Create) =
{
	params ["_category", "_area"];

	OO_SET(_category,ForceCategory,Area,_area);
};

OO_TRACE_DECL(SPM_AirPatrol_Delete) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Root,Delete,ForceCategory);

	private _airfieldStrongpoint = OO_GET(_category,AirPatrolCategory,AirfieldStrongpoint);
	if (not OO_ISNULL(_airfieldStrongpoint)) then
	{
		call OO_DELETE(_airfieldStrongpoint);
	};
};

OO_BEGIN_SUBCLASS(AirPatrolCategory,ForceCategory);
	OO_OVERRIDE_METHOD(AirPatrolCategory,Root,Create,SPM_AirPatrol_Create);
	OO_OVERRIDE_METHOD(AirPatrolCategory,Root,Delete,SPM_AirPatrol_Delete);
	OO_OVERRIDE_METHOD(AirPatrolCategory,Category,Update,SPM_AirPatrol_Update);
	OO_DEFINE_PROPERTY(AirPatrolCategory,Airfield,"ARRAY",[]);
	OO_DEFINE_PROPERTY(AirPatrolCategory,AirfieldStrongpoint,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(AirPatrolCategory,AirfieldAirDefense,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(AirPatrolCategory,PatrolType,"STRING","area"); // area, target
	OO_DEFINE_PROPERTY(AirPatrolCategory,_CallupTime,"SCALAR",0);
	OO_DEFINE_PROPERTY(AirPatrolCategory,CallupInterval,"ARRAY",CALLUP_INTERVAL);
OO_END_SUBCLASS(AirPatrolCategory);
