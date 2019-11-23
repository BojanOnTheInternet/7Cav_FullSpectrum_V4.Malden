/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

#ifdef TEST
#define CALLUP_INTERVAL	[10,10]
#define RETIRE_INTERVAL	[10,10]
#else
#define CALLUP_INTERVAL	[300,600]
#define RETIRE_INTERVAL	[60,60]
#endif

// Don't spawn armor at a given location if any player is within this distance
#define SPAWN_PROXIMITY_DISTANCE 200

OO_TRACE_DECL(SPM_Armor_WS_TargetDestroyed) =
{
	params ["_leader", "_units", "_category"];

	[_category, group _leader] call SPM_Armor_Task_Patrol;
};

OO_TRACE_DECL(SPM_Armor_TC_Patrol) =
{
	params ["_task", "_category"];

	private _group = [_task] call SPM_TaskGetObject;

	[_category, _group] call SPM_Armor_Task_Patrol;
};

OO_TRACE_DECL(SPM_Armor_Task_Patrol) =
{
	params ["_category", "_patrolGroup"];

	switch (OO_GET(_category,ArmorCategory,PatrolType)) do
	{
		case "area":
		{
			[vehicle leader _patrolGroup, "ArmorStatus", "Patrol"] call TRACE_SetObjectString;

			private _area = OO_GET(_category,ForceCategory,Area);

			private _minRadius = OO_GET(_area,StrongpointArea,InnerRadius);
			private _maxRadius = OO_GET(_area,StrongpointArea,OuterRadius);
			private _circumference = 2 * pi * ((_minRadius + _maxRadius) / 2.0);

			_task = [_patrolGroup, OO_GET(_area,StrongpointArea,Position), _minRadius, _maxRadius, random 1 < 0.5, _circumference * 0.05, _circumference * 0.1, 0, 0, 0] call SPM_fnc_patrolPerimeter;
			[_task, SPM_Armor_TC_Patrol, _category] call SPM_TaskOnComplete;
		};
		
		case "target":
		{
			[_patrolGroup] call SPM_DeletePatrolWaypoints;

			//TODO: Be more intelligent about target selection.  Consider known 'targets' of this unit.  Consider distribution of east
			// units on west units so that they don't all go for the same west unit.
			private _westForce = [OO_GET(_category,ForceCategory,RangeWest)] call OO_METHOD(_category,ForceCategory,GetForceLevelsWest);
			if (count _westForce > 0) then
			{
				private _targetForce = selectRandom _westForce;
				private _targetVehicle = OO_GET(_targetForce,ForceUnit,Vehicle);

				private _waypoint = [_patrolGroup, getPos _targetVehicle] call SPM_AddPatrolWaypoint;
				_waypoint waypointAttachVehicle _targetVehicle;
				_waypoint setWaypointType "destroy";
				[_waypoint, SPM_Armor_WS_TargetDestroyed, _category] call SPM_AddPatrolWaypointStatements;

				[vehicle leader _patrolGroup, "ArmorStatus", "Target"] call TRACE_SetObjectString;
			};
		};
	};
};

OO_TRACE_DECL(SPM_Armor_WS_Salvage) =
{
	params ["_leader", "_units", "_category"];

	[vehicle _leader, "ArmorStatus", nil] call TRACE_SetObjectString;

	if (not ((vehicle _leader) isKindOf "Air")) then
	{
		[_category, group _leader] call SPM_Force_SalvageForceUnit;
	}
	else
	{
		(vehicle _leader) land "land";

		[_category, group _leader] spawn
		{
			params ["_category", "_group"];

			[{ isTouchingGround leader _group }, 30, 5] call JB_fnc_timeoutWaitUntil;

			[_category, _group] call SPM_Force_SalvageForceUnit;
		};
	};
};

SPM_Armor_AntiArmorWeapons =
[
	["arifle_Katiba_GL*", true],
	["arifle_Mk20_GL*", true],
	["arifle_AK12_GL*", true],
	["arifle_CTAR_GL_*", true],
	["arifle_MX_GL*", true],
	["arifle_TRG21_GL*", true],
	["arifle_SPAR_01_GL*", true],
	["launch_MRAWS_green_F", true],
	["launch_MRAWS_olive_F", true],
	["launch_MRAWS_sand_F", true],
	["launch_RPG32*", true],
	["launch_RPG7*", true]
];

OO_TRACE_DECL(SPM_Armor_IgnoreInfantry) =
{
	_this spawn
	{
		params ["_vehicle"];

		while { alive _vehicle } do
		{
			{
				if (_x isKindOf "Man" && { not (_x isKindOf "B_crew_F") } && { _x distance _vehicle > 20 } && { { [_x, SPM_Armor_AntiArmorWeapons] call JB_fnc_passesTypeFilter } count weapons _x == 0 }) then
				{
					_vehicle forgetTarget _x;
				};
			} forEach (effectiveCommander _vehicle targets [true]);

			sleep 1; // 1 second shuts down attacks.  2 seconds reduces them.  3 seconds produces no reduction.  forgetTarget may be intended for use in FSMs.
		};
	};
};

OO_TRACE_DECL(SPM_Armor_IgnoreUnarmed) =
{
	_this spawn
	{
		params ["_vehicle"];

		while { alive _vehicle } do
		{
			{
				if (_x distance _vehicle > 100 && { not ([vehicle _x] call SPM_Util_HasOffensiveWeapons) }) then
				{
					_vehicle forgetTarget _x;
				};
			} forEach (effectiveCommander _vehicle targets [true]);

			sleep 1; // 1 second shuts down attacks.  2 seconds reduces them.  3 seconds produces no reduction.  forgetTarget may be intended for use in FSMs.
		};
	};
};

OO_TRACE_DECL(SPM_Armor_Retire) =
{
	params ["_forceUnitIndex", "_parameters"];

	_parameters params ["_category", "_allowReinstate"];

	private _forceUnit = OO_GET(_category,ForceCategory,ForceUnits) select _forceUnitIndex;

	// If already retiring, return
	if ([_forceUnit] call SPM_Force_IsRetiring) exitWith {};

	private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	if (not _allowReinstate) then { _vehicle setVariable ["SPM_Force_AllowReinstate", false] };

	private _retirementPosition = _vehicle getVariable "SPM_Armor_CallupPosition";
	private _extendedPosition = [];

	private _preplacedEquipment = _vehicle getVariable ["SPM_Force_PreplacedEquipment", false];

	if (not _preplacedEquipment) then
	{
		private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
		private _center = OO_GET(_strongpoint,Strongpoint,Position);
		private _radius = OO_GET(_strongpoint,Strongpoint,ActivityRadius);

		if (_center distance _retirementPosition < _radius) then
		{
			private _approachDirection = OO_GET(_category,ForceCategory,CallupDirection);
			private _spawnpoint = [_center, _radius, OO_GET(_category,ForceCategory,SideWest), _approachDirection select 0, _approachDirection select 1] call SPM_Util_GetGroundSpawnpoint;
			if (count (_spawnpoint select 0) > 0) then { _retirementPosition = _spawnpoint select 0 };
		};

		if (not (_vehicle isKindOf "Air")) then
		{
			private _centerToRetirement = _center vectorFromTo _retirementPosition;
			private _positions = [_retirementPosition vectorAdd (_centerToRetirement vectorMultiply 75), 0, 50, 10] call SPM_Util_SampleAreaGrid;
			[_positions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
			[_positions, 5.0, ["WALL", "BUILDING", "HOUSE", "ROCK", "TREE"]] call SPM_Util_ExcludeSamplesByProximity;

			if (count _positions > 0) then
			{
				_retirementPosition = selectRandom _positions;
			};
		};

		private _toRetirementPosition = getPos _vehicle vectorFromTo _retirementPosition;
		_extendedPosition = _retirementPosition vectorAdd (_toRetirementPosition vectorMultiply 500); // To keep the vehicle moving at speed through its retirement position, particularly aircraft
	};

	private _group = [] call OO_METHOD(_forceUnit,ForceUnit,GetGroup);

	[_group] call SPM_DeletePatrolWaypoints;

	[units _group] call SPM_Util_AIOnlyMove; //TODO: If the crew is fixing the vehicle, they won't be able to mount up to leave

	private _waypoint = [_group, _retirementPosition] call SPM_AddPatrolWaypoint;
	[_waypoint, SPM_Armor_WS_Salvage, _category] call SPM_AddPatrolWaypointStatements;
	if (count _extendedPosition > 0) then { [_group, _extendedPosition] call SPM_AddPatrolWaypoint };

	[_forceUnit, true] call SPM_Force_SetRetiring;

	[_vehicle, "ArmorStatus", "Retired"] call TRACE_SetObjectString;
};

OO_TRACE_DECL(SPM_Armor_Reinstate) =
{
	params ["_forceUnitIndex", "_category"];

	private _forceUnit = OO_GET(_category,ForceCategory,ForceUnits) select _forceUnitIndex;

	private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);
	[_vehicle, "ArmorStatus", nil] call TRACE_SetObjectString;

	private _group = [] call OO_METHOD(_forceUnit,ForceUnit,GetGroup);

	[_group] call SPM_DeletePatrolWaypoints;

	[units _group] call SPM_Util_AIFullCapability;

	[_forceUnit, false] call SPM_Force_SetRetiring;
	[_category, _group] call SPM_Armor_Task_Patrol;
};

OO_TRACE_DECL(SPM_Armor_CreateUnit) =
{
	params ["_category", "_position", "_direction", "_callup"];

	private _unitVehicle = objNull;

	if (_callup isEqualType objNull) then
	{
		_unitVehicle = _callup;
		_unitVehicle setVariable ["SPM_Force_PreplacedEquipment", true];
		_position = getPosATL _unitVehicle;

		// Bring the vehicle's turrets local so that the crew will go in properly.  This can take multiple seconds.
		if (not local _unitVehicle) then
		{
			_unitVehicle setOwner clientOwner;
			waitUntil { not alive _unitVehicle || { local _unitVehicle } };
			waitUntil { not alive _unitVehicle || { allTurrets _unitVehicle findIf { (_unitVehicle turretOwner _x) != clientOwner } == -1 } };
		};
	}
	else
	{
		_unitVehicle = [_callup select 0, _position, _direction, "fly"] call SPM_fnc_spawnVehicle;
		[_unitVehicle] call (_callup select 1 select 3);

		_unitVehicle setVehicleTIPars [1.0, 0.5, 0.0]; // Start vehicle hot so it shows on thermals

		switch (true) do
		{
			case (_unitVehicle isKindOf "LandVehicle"):
			{
				[_unitVehicle, 40] call JB_fnc_limitSpeed;
			};
			case (_unitVehicle isKindOf "Air"):
			{
				_unitVehicle flyInHeight (((getPos _unitVehicle) select 2) max 50);
			};
		};
	};

	_unitVehicle setVariable ["SPM_Force_CalledUnit", true];
	_unitVehicle setVariable ["SPM_Armor_CallupPosition", _position];

	private _crew = [_unitVehicle] call SPM_fnc_groupFromVehicleCrew;
	private _crewDescriptor = _crew select 1;

	private _sideEast = OO_GET(_category,ForceCategory,SideEast);
	private _unitGroup = [_sideEast, [[_unitVehicle]] + _crewDescriptor, [_unitVehicle, 0.0] call SPM_PositionInFrontOfVehicle, 0, true] call SPM_fnc_spawnGroup;
	(driver _unitVehicle) setUnitTrait ["engineer", true];
	(driver _unitVehicle) addBackpack "B_LegStrapBag_black_repair_F";

	[_category, _unitVehicle] call OO_GET(_category,Category,InitializeObject);
	[_category, _unitGroup] call OO_GET(_category,Category,InitializeObject);

	_unitGroup setSpeedMode "full";

	private _forceUnit = [_unitVehicle, units _unitGroup] call OO_CREATE(ForceUnit);
	OO_GET(_category,ForceCategory,ForceUnits) pushBack _forceUnit;

	// If called up against the reserves of the category, subtract the appropriate amount
	if (_callup isEqualType []) then
	{
		private _forceRatings = [OO_GET(_forceUnit,ForceUnit,Units), OO_GET(_category,ForceCategory,RatingsEast)] call SPM_Force_GetForceRatings;

		if (count _forceRatings == 0) then
		{
			diag_log format ["SPM_Armor_CreateUnit: no force rating available for %1.  Created unit not charged against category reserves.", typeOf _unitVehicle];
		}
		else
		{
			private _reserves = OO_GET(_category,ForceCategory,Reserves) - OO_GET(_forceRatings select 0,ForceRating,Rating);
			OO_SET(_category,ForceCategory,Reserves,_reserves);
		};
	};

	_forceUnit
};

OO_TRACE_DECL(SPM_Armor_CallUp) =
{
	params ["_position", "_direction", "_category", "_callup"];

	private _pendingCallups = OO_GET(_category,ForceCategory,PendingCallups) - 1;
	OO_SET(_category,ForceCategory,PendingCallups,_pendingCallups);

	if (OO_GET(_category,ForceCategory,_Surrendered)) exitWith {};

	private _forceUnit = [_category, _position, _direction, _callup] call SPM_Armor_CreateUnit;
	private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	if (isNull _vehicle) exitWith {};

	[_category, group (OO_GET(_forceUnit,ForceUnit,Units) select 0)] call SPM_Armor_Task_Patrol;

	if (_callup isEqualType []) then
	{
		[_vehicle, 20, 10, 20] call SPM_Util_WaitForVehicleToMove;

		if (not alive _vehicle || { _position distance _vehicle < 10 }) exitWith
		{
			[_category, _forceUnit] call SPM_Force_SalvageForceUnit;
		};
	};
};

OO_TRACE_DECL(SPM_Armor_Create) =
{
	params ["_category", "_area"];

	OO_SET(_category,ForceCategory,Area,_area);
};

OO_TRACE_DECL(SPM_Armor_Delete) =
{
	params ["_category"];

	private _sideWest = OO_GET(_category,ForceCategory,SideWest);

	private _forceUnits = OO_GET(_category,ForceCategory,ForceUnits);
	[_forceUnits, _sideWest] call SPM_Armor_RemoveCapturedForceUnits;

	[] call OO_METHOD_PARENT(_category,Root,Delete,ForceCategory);
};

OO_TRACE_DECL(SPM_Armor_Command) =
{
	params ["_category", "_command", "_parameters"];

	if (_command != "surrender") exitWith { [_command, _parameters] call OO_METHOD_PARENT(_category,Category,Command,ForceCategory) };

	OO_SET(_category,ForceCategory,_Surrendered,true);

	{
		[_forEachIndex, [_category, false]] call SPM_Armor_Retire;

		private _vehicle = OO_GET(_x,ForceUnit,Vehicle);
		if ({ alive _x } count crew _vehicle > 0 && { _vehicle isKindOf "Tank" || _vehicle isKindOf "Car" }) then { _vehicle forceFlagTexture "\A3\Data_F\Flags\Flag_white_CO.paa" };

		//TODO: If fired upon by player, take away ammo from firing vehicle

	} forEach OO_GET(_category,ForceCategory,ForceUnits);
};

OO_TRACE_DECL(SPM_Armor_BeginTemporaryDuty) =
{
	params ["_category"];

	private _forceUnits = OO_GET(_category,ForceCategory,ForceUnits);

	if (count _forceUnits == 0) exitWith { diag_log "SPM_Armor_BeginTemporaryDuty: No units available"; [objNull, []] call OO_CREATE(ForceUnit) };

	private _dutyUnits = OO_GET(_category,ArmorCategory,DutyUnits);
	private _dutyVehicles = _dutyUnits apply { OO_GET(_x,ForceUnit,Vehicle) };

	private _availableUnits = _forceUnits select { not isNull OO_GET(_x,ForceUnit,Vehicle) && { not (OO_GET(_x,ForceUnit,Vehicle) in _dutyVehicles) } };

	if (count _availableUnits == 0) exitWith { diag_log "SPM_Armor_BeginTemporaryDuty: No units available"; [objNull, []] call OO_CREATE(ForceUnit) };

	private _dutyUnit = selectRandom _availableUnits;

	OO_GET(_dutyUnit,ForceUnit,Vehicle) setVariable ["SPM_Force_AllowRetire", false];
	_dutyUnits pushBack _dutyUnit;

	private _group = [] call OO_METHOD(_dutyUnit,ForceUnit,GetGroup);
	[_group] call SPM_DeletePatrolWaypoints;

	_dutyUnit
};

OO_TRACE_DECL(SPM_Armor_EndTemporaryDuty) =
{
	params ["_category", "_forceUnit"];

	private _dutyUnits = OO_GET(_category,ArmorCategory,DutyUnits);
	private _group = [] call OO_METHOD(_forceUnit,ForceUnit,GetGroup);

	private _index = _dutyUnits findIf { _group == ([] call OO_METHOD(_x,ForceUnit,GetGroup)) };
	if (_index == -1) exitWith { diag_log format ["SPM_Armor_EndTemporaryDuty: unknown duty unit: %1", _forceUnit] };

	OO_GET(_forceUnit,ForceUnit,Vehicle) setVariable ["SPM_Force_AllowRetire", nil];

	[_category, _group] call SPM_Armor_Task_Patrol;

	_dutyUnits deleteAt _index
};

OO_TRACE_DECL(SPM_Armor_RemoveCapturedForceUnits) =
{
	params ["_forceUnits", "_sideWest"];

	for "_i" from (count _forceUnits - 1) to 0 step -1 do
	{
		private _forceUnit = _forceUnits select _i;
		private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);
		if (side _vehicle == _sideWest) then
		{
			OO_SET(_forceUnit,ForceUnit,Vehicle,objNull);

			// Remove any trace labels
			[_vehicle, "ArmorStatus", nil] call TRACE_SetObjectString;

			// Make sure there are no speed limitations on the vehicle
			[_vehicle, -1] call JB_fnc_limitSpeed;

			// Delete vehicle if abandoned
			[_vehicle] call JB_fnc_respawnVehicleInitialize;
			[_vehicle, 300, 60, 0, true] call JB_fnc_respawnVehicleWhenAbandoned;
		};
	};
};

// Create a list of the category's callup types that have been preplaced in the category's area.  The list is [[type,count], ...]
OO_TRACE_DECL(SPM_Armor_PreplacedEquipment) =
{
	params ["_category"];

	private _area = OO_GET(_category,ForceCategory,Area);
	private _center = OO_GET(_area,StrongpointArea,Position);
	private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _ratingsEast = OO_GET(_category,ForceCategory,RatingsEast);
	private _preplacedTypes = _ratingsEast apply { _x select 0 };
	private _preplacedUnits = _center nearEntities [_preplacedTypes, _outerRadius] select { _x distance _center >= _innerRadius };

	OO_TRACE_SYMBOL(_ratingsEast);
	OO_TRACE_SYMBOL(_preplacedTypes);

	private _type = "";
	_preplacedUnits = _preplacedUnits select { not (_x getVariable ["SPM_Force_CalledUnit", false]) && { count crew _x == 0 } && { simulationEnabled _x } && { [_x] call SPM_Force_IsCombatEffectiveVehicle } };
	_preplacedUnits = _preplacedTypes apply { _type = _x; [_type, _preplacedUnits select { _x isKindOf _type }] };
	_preplacedUnits = _preplacedUnits select { count (_x select 1) > 0 };

	OO_TRACE_SYMBOL(_preplacedUnits);

	_preplacedUnits
};

OO_TRACE_DECL(SPM_Armor_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,ForceCategory);

	private _sideWest = OO_GET(_category,ForceCategory,SideWest);

	private _forceUnits = OO_GET(_category,ForceCategory,ForceUnits);
	[_forceUnits, _sideWest] call SPM_Armor_RemoveCapturedForceUnits;
	[_forceUnits, 100, _sideWest] call SPM_Force_DeleteEnemiesOnBases;

	if (OO_GET(_category,ForceCategory,_Surrendered)) exitWith {};

	[_forceUnits, SPM_Armor_Retire, [_category, false]] call SPM_Force_ForEachDepleted;

	// Retask any active units that have no target or that have succeeded in getting the crew out of their target vehicle
	if (OO_GET(_category,ArmorCategory,PatrolType) == "target") then
	{
		private _units = [];
		private _vehicle = objNull;
		private _group = grpNull;

		{
			_units = OO_GET(_x,ForceUnit,Units) select { alive _x };
			if (count _units > 0) then
			{
				_group = group (_units select 0);
				if (currentWaypoint _group == count waypoints _group) then
				{
					[_category, _group] call SPM_Armor_Task_Patrol;
				}
				else
				{
					_vehicle = waypointAttachedVehicle ((waypoints _group) select (currentWaypoint _group));
					if (count ((crew _vehicle) select { alive _x }) == 0) then
					{
						[_category, _group] call SPM_Armor_Task_Patrol;
					};
				};
			};
		} forEach (_forceUnits select { not ([_x] call SPM_Force_IsRetiring) });
	};

	[_forceUnits, { not alive OO_GET(_x,ForceUnit,Vehicle) }] call SPM_Force_DeleteForceUnits; //TODO: Retire?

	private _westForce = [OO_GET(_category,ForceCategory,RangeWest)] call OO_METHOD(_category,ForceCategory,GetForceLevelsWest);
	private _eastForce = [-1] call OO_METHOD(_category,ForceCategory,GetForceLevelsEast);

	_westForce = _westForce select { canFire OO_GET(_x,ForceRating,Vehicle) };

	private _preplacedEquipment = if (OO_GET(_category,ArmorCategory,UsePreplacedEquipment)) then { [_category] call SPM_Armor_PreplacedEquipment } else { [] };

	private _changes = [_category, _westForce, _eastForce, _preplacedEquipment] call SPM_Force_Rebalance;

	private _units = OO_GET(_category,ForceCategory,ForceUnits);

	// Retires only every RETIRE_INTERVAL
	private _retireTime = OO_GET(_category,ArmorCategory,_RetireTime);

	if (diag_tickTime > _retireTime) then
	{
		private _retireInterval = OO_GET(_category,ArmorCategory,RetireInterval);
		private _retireTime = diag_tickTime + (_retireInterval select 0) + (random ((_retireInterval select 1) - (_retireInterval select 0)));
		OO_SET(_category,ArmorCategory,_RetireTime,_retireTime);

		{
			[[_units, { OO_GET(_this select 0,ForceUnit,Vehicle) == (_this select 1) }, _x] call SPM_Util_Find, [_category, true]] call SPM_Armor_Retire;
		} forEach CHANGES(_changes,retire);
	};

	{
		[[_units, { OO_GET(_this select 0,ForceUnit,Vehicle) == (_this select 1) }, _x] call SPM_Util_Find, _category] call SPM_Armor_Reinstate;
	} forEach CHANGES(_changes,reinstate);

	// Callups only every CALLUP_INTERVAL
	private _callupTime = OO_GET(_category,ArmorCategory,_CallupTime);

	if (diag_tickTime >= _callupTime) then
	{
		private _callupInterval = OO_GET(_category,ArmorCategory,CallupInterval);
		private _callupTime = diag_tickTime + (_callupInterval select 0) + (random ((_callupInterval select 1) - (_callupInterval select 0)));
		OO_SET(_category,ArmorCategory,_CallupTime,_callupTime);

		if (count CHANGES(_changes,callup) > 0 && OO_GET(_category,ForceCategory,PendingCallups) == 0) then
		{
			private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
			private _spawnManager = OO_GET(_strongpoint,Strongpoint,SpawnManager);

			private _area = OO_GET(_category,ForceCategory,Area);
			private _center = OO_GET(_area,StrongpointArea,Position);
			private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
			private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

			// On the very first rebalance, assume that the vehicles can be scattered around the interior of the armor area.  All other times,
			// they must drive in from the perimeter.
			if (OO_GET(_category,ForceCategory,_FirstRebalance)) then
			{
				private _positions = [_center, _innerRadius, _outerRadius, OO_GET(_category,ForceCategory,SideWest)] call SPM_Util_GetInteriorSpawnPositions;

				{
					if (count _positions == 0) exitWith {};

					private _position = _positions deleteAt (floor random count _positions);

					[_position, random 360, SPM_Armor_CallUp, [_category, _x]] call OO_METHOD(_spawnManager,SpawnManager,ScheduleSpawn);

					private _pendingCallups = OO_GET(_category,ForceCategory,PendingCallups) + 1;
					OO_SET(_category,ForceCategory,PendingCallups,_pendingCallups);
				} forEach CHANGES(_changes,callup);
			}
			else
			{
				private _approachDirection = OO_GET(_category,ForceCategory,CallupDirection);

				private _groundSpawnpoint = [];
				private _airSpawnpoints = [];

				private _getSpawnpoint =
				{
					params ["_objectType"];

					if (_objectType isKindOf "Air") exitWith
					{
						if (count _airSpawnpoints == 0) then { _airSpawnpoints = [0, 1, 2] apply { [OO_GET(_strongpoint,Strongpoint,Position), OO_GET(_strongpoint,Strongpoint,ActivityRadius), 1500, 100 + random 100, _approachDirection select 0, _approachDirection select 1] call SPM_Util_GetAirSpawnpoint } };
						selectRandom _airSpawnpoints
					};

					if (count _groundSpawnpoint == 0) then
					{
						_groundSpawnpoint = [OO_GET(_strongpoint,Strongpoint,Position), OO_GET(_strongpoint,Strongpoint,ActivityRadius), _center, _outerRadius, OO_GET(_category,ForceCategory,SideWest), _approachDirection select 0, _approachDirection select 1] call SPM_Util_GetRoadSpawnpoint;
						if (count (_groundSpawnpoint select 0) == 0) then { _groundSpawnpoint = [OO_GET(_strongpoint,Strongpoint,Position), OO_GET(_strongpoint,Strongpoint,ActivityRadius), OO_GET(_category,ForceCategory,SideWest), _approachDirection select 0, _approachDirection select 1] call SPM_Util_GetGroundSpawnpoint };
					};
					_groundSpawnpoint
				};

				{
					private _objectType = if (_x isEqualType []) then { _x select 0 } else { typeOf _x };
					private _spawnpoint = [_objectType] call _getSpawnpoint;

					[_spawnpoint select 0, _spawnpoint select 1, SPM_Armor_CallUp, [_category, _x]] call OO_METHOD(_spawnManager,SpawnManager,ScheduleSpawn);

					private _pendingCallups = OO_GET(_category,ForceCategory,PendingCallups) + 1;
					OO_SET(_category,ForceCategory,PendingCallups,_pendingCallups);
				} forEach CHANGES(_changes,callup);
			};
		};
	};
};

OO_BEGIN_SUBCLASS(ArmorCategory,ForceCategory);
	OO_OVERRIDE_METHOD(ArmorCategory,Root,Create,SPM_Armor_Create);
	OO_OVERRIDE_METHOD(ArmorCategory,Root,Delete,SPM_Armor_Delete);
	OO_OVERRIDE_METHOD(ArmorCategory,Category,Update,SPM_Armor_Update);
	OO_OVERRIDE_METHOD(ArmorCategory,Category,Command,SPM_Armor_Command);
	OO_DEFINE_METHOD(ArmorCategory,CreateUnit,SPM_Armor_CreateUnit);
	OO_DEFINE_METHOD(ArmorCategory,BeginTemporaryDuty,SPM_Armor_BeginTemporaryDuty);
	OO_DEFINE_METHOD(ArmorCategory,EndTemporaryDuty,SPM_Armor_EndTemporaryDuty);
	OO_DEFINE_PROPERTY(ArmorCategory,PatrolType,"STRING","area"); // area, target
	OO_DEFINE_PROPERTY(ArmorCategory,DutyUnits,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ArmorCategory,_CallupTime,"SCALAR",0);
	OO_DEFINE_PROPERTY(ArmorCategory,CallupInterval,"ARRAY",CALLUP_INTERVAL);
	OO_DEFINE_PROPERTY(ArmorCategory,_RetireTime,"SCALAR",0);
	OO_DEFINE_PROPERTY(ArmorCategory,RetireInterval,"ARRAY",RETIRE_INTERVAL);
	OO_DEFINE_PROPERTY(ArmorCategory,UsePreplacedEquipment,"BOOL",false); // Attempt to find empty vehicles of the type listed in ForceCategory,EastRatings and activate them as they are.
OO_END_SUBCLASS(ArmorCategory);
