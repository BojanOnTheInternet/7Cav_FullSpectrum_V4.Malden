/*
Copyright (c) 2017, John Buehler

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
#define CALLUP_INTERVAL	[120,180]
#define RETIRE_INTERVAL	[60,60]
#endif

// Don't spawn armor at a given location if any player is within this distance
#define SPAWN_PROXIMITY_DISTANCE 200

SPM_Armor_RatingsWestTanks =
[
	["B_MBT_01_cannon_F", [45, 3]],
	["B_MBT_01_TUSK_F", [50, 3]],
	["B_T_MBT_01_cannon_F", [45, 3]],
	["B_T_MBT_01_TUSK_F", [50, 3]],
	["rhsusf_m1a2sep1tuskiiwd_usarmy", [50, 3]],
	["rhsusf_m1a2sep1tuskiid_usarmy", [50, 3]],

	["B_AFV_Wheeled_01_cannon_F", [40, 3]],

	["O_MBT_04_cannon_F", [50, 3]],
	["O_MBT_02_cannon_F", [50, 3]],

	["I_MBT_03_cannon_F", [50, 3]]
];

SPM_Armor_RatingsWestAPCs =
[
//	["B_APC_Wheeled_01_cannon_F", [25, 3]],

	["RHS_M2A3_BUSKIII_wd", [25, 3]],

	["O_APC_Tracked_02_cannon_F", [30, 3]],
	["O_APC_Wheeled_02_rcws_F", [20, 3]],

	["I_APC_tracked_03_cannon_F", [35, 3]],
	["I_APC_Wheeled_03_cannon_F", [25, 3]]
];

SPM_Armor_RatingsWestAir =
[
	["B_Heli_Light_01_F", [30, 2]],
	["B_Heli_Light_01_dynamicLoadout_F", [30, 2]],
	["B_Heli_Attack_01_F", [75, 2]],
	["B_Heli_Attack_01_dynamicLoadout_F", [75, 2]],
	["B_Plane_CAS_01_F", [100, 1]],
	["B_Plane_CAS_01_dynamicLoadout_F", [100, 1]],
	["B_T_VTOL_01_armed_F", [60, 3]],
	["RHS_MELB_AH6M", [30, 2]],
	["RHS_AH64D", [75, 2]],

	["O_Plane_CAS_02_F", [150, 1]],
	["O_Plane_CAS_02_dynamicLoadout_F", [150, 1]],
	["O_Heli_Attack_02_F", [100, 2]],
	["O_Heli_Attack_02_dynamicLoadout_F", [100, 2]],
	["O_Heli_Light_02_F", [50, 2]],
	["O_Heli_Light_02_dynamicLoadout_F", [50, 2]],
	["O_T_VTOL_02_infantry_F", [100, 2]],
	["O_T_VTOL_02_infantry_dynamicLoadout_F", [100, 2]],
	["FIR_A10C", [150, 1]],
	["FIR_F16C", [150, 1]],

	["I_Plane_Fighter_03_CAS_F", [75, 1]]
];

SPM_Armor_RatingsWestAirDefense =
[
	["B_APC_Tracked_01_AA_F", [50, 3]]
];

SPM_Armor_CallupsEastAPCs =
[
	["LOP_US_BMP2D",
		[25, 3, 1.0,
			{
			}]],
	["LOP_US_BTR70",
		[25, 3, 1.0,
			{
			}]],
	["LOP_US_BMP1",
		[25, 3, 1.0,
			{
			}]]
];

SPM_Armor_RatingsEastAPCs = SPM_Armor_CallupsEastAPCs apply { [_x select 0, (_x select 1) select [0, 2]] };

SPM_Armor_CallupsEastTanks =
[
	["LOP_US_T72BC",
		[60, 3, 1.0,
			{
			}]],

	["LOP_US_T72BB",
		[60, 3, 1.0,
			{
			}]]
];

SPM_Armor_RatingsEastTanks = SPM_Armor_CallupsEastTanks apply { [_x select 0, (_x select 1) select [0, 2]] };

SPM_Armor_CallupsEastAir =
[
	["RHS_Mi8mt_vvsc", [120, 3, 1.0,
			{
				params ["_unit"];

				[_unit] call SPM_Armor_IgnoreUnarmed;
			}]],
	["RHS_Mi8MTV3_vvsc", [160, 3, 1.0,
			{
			}]],
	["rhs_mi28n_vvsc", [180, 2, 1.0,
			{
				params ["_unit"];

				[_unit] call SPM_Armor_IgnoreInfantry;
			}]],
	["RHS_Ka52_vvsc", [210, 2, 1.0,
			{
				params ["_unit"];

				[_unit] call SPM_Armor_IgnoreInfantry;
			}]]
];

SPM_Armor_RatingsEastAir = SPM_Armor_CallupsEastAir apply { [_x select 0, (_x select 1) select [0, 2]] };

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
			private _area = OO_GET(_category,ForceCategory,Area);

			private _minRadius = OO_GET(_area,StrongpointArea,InnerRadius);
			private _maxRadius = OO_GET(_area,StrongpointArea,OuterRadius);
			private _circumference = 2 * pi * ((_minRadius + _maxRadius) / 2.0);

			_task = [_patrolGroup, OO_GET(_area,StrongpointArea,Position), _minRadius, _maxRadius, random 1 < 0.5, _circumference * 0.05, _circumference * 0.1, 0, 0, 0] call SPM_fnc_patrolPerimeter;
			[_task, SPM_Armor_TC_Patrol, _category] call SPM_TaskOnComplete;
		};
		
		case "target":
		{
			private _westForce = [OO_GET(_category,ForceCategory,RangeWest)] call OO_METHOD(_category,ForceCategory,GetForceLevelsWest);
			if (count _westForce > 0) then
			{
				private _targetForce = selectRandom _westForce;
				private _targetVehicle = OO_GET(_targetForce,ForceUnit,Vehicle);

				[_patrolGroup] call SPM_DeletePatrolWaypoints;

				private _waypoint = [_patrolGroup, getPos _targetVehicle] call SPM_AddPatrolWaypoint;
				_waypoint waypointAttachVehicle _targetVehicle;
				_waypoint setWaypointType "destroy";
				[_waypoint, SPM_Armor_WS_TargetDestroyed, _category] call SPM_AddPatrolWaypointStatements;
			};
		};
	};
};

OO_TRACE_DECL(SPM_Armor_WS_Salvage) =
{
	params ["_leader", "_units", "_category"];

	[_category, group _leader] call SPM_Force_SalvageForceUnit;
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

	private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
	private _center = OO_GET(_strongpoint,Strongpoint,Position);
	private _radius = OO_GET(_strongpoint,Strongpoint,ActivityRadius);

	private _forceUnit = OO_GET(_category,ForceCategory,ForceUnits) select _forceUnitIndex;
	private _units = OO_GET(_forceUnit,ForceUnit,Units);
	private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	// If already retiring, return
	if ((group driver _vehicle) getVariable ["SPM_Force_Retiring", false]) exitWith {};

	if (not _allowReinstate) then { _vehicle setVariable ["SPM_Force_AllowReinstate", false] };

	private _retirementPosition = _vehicle getVariable "SPM_Armor_CallupPosition";
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
	private _extendedPosition = _retirementPosition vectorAdd (_toRetirementPosition vectorMultiply 500); // To keep the vehicle moving at speed through its retirement position, particularly aircraft

	[_vehicle, "ArmorStatus", "Retired"] call TRACE_SetObjectString;

	{
		[_x] call SPM_DeletePatrolWaypoints;

		[units _x] call SPM_Util_AIOnlyMove; //TODO: If the crew is fixing the vehicle, they won't be able to mount up to leave

		private _waypoint = [_x, _retirementPosition] call SPM_AddPatrolWaypoint;
		[_waypoint, SPM_Armor_WS_Salvage, _category] call SPM_AddPatrolWaypointStatements;
		[_x, _extendedPosition] call SPM_AddPatrolWaypoint;

		_x setVariable ["SPM_Force_Retiring", true];

	} forEach ([] call OO_METHOD(_forceUnit,ForceUnit,GetGroups));
};

OO_TRACE_DECL(SPM_Armor_Reinstate) =
{
	params ["_forceUnitIndex", "_category"];

	private _forceUnit = OO_GET(_category,ForceCategory,ForceUnits) select _forceUnitIndex;

	private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);
	[_vehicle, "ArmorStatus", nil] call TRACE_SetObjectString;

	{
		[_x] call SPM_DeletePatrolWaypoints;

		[units _x] call SPM_Util_AIFullCapability;

		_x setVariable ["SPM_Force_Retiring", nil];
		[_category, _x] call SPM_Armor_Task_Patrol;
	} forEach ([] call OO_METHOD(_forceUnit,ForceUnit,GetGroups));
};

OO_TRACE_DECL(SPM_Armor_CreateUnit) =
{
	params ["_category", "_position", "_direction", "_type"];

	private _index = OO_GET(_category,ForceCategory,CallupsEast) findIf { _x select 0 == _type };
	if (_index == -1) exitWith {};
	private _vehicleDescriptor = OO_GET(_category,ForceCategory,CallupsEast) select _index select 1;

	private _unitVehicle = [_type, _position, _direction, "fly"] call SPM_fnc_spawnVehicle;
	_unitVehicle setVehicleTIPars [1.0, 0.5, 0.0]; // Start vehicle hot so it shows on thermals

	private _crew = [_unitVehicle] call SPM_fnc_groupFromVehicleCrew;
	private _crewDescriptor = _crew select 1;

	private _sideEast = OO_GET(_category,ForceCategory,SideEast);
	private _unitGroup = [_sideEast, [[_unitVehicle]] + _crewDescriptor, [_unitVehicle, 0.0] call SPM_PositionInFrontOfVehicle, 0, true] call SPM_fnc_spawnGroup;
	(driver _unitVehicle) setUnitTrait ["engineer", true];
	(driver _unitVehicle) addBackpack "B_LegStrapBag_black_repair_F";

	[_unitVehicle] call (_vehicleDescriptor select 3);
	[_category, _unitGroup] call OO_GET(_category,Category,InitializeObject);
	[_category, _unitVehicle] call OO_GET(_category,Category,InitializeObject);

	_unitVehicle setVariable ["SPM_Armor_CallupPosition", _position];

	_unitGroup setSpeedMode "full";

	switch (true) do
	{
		case (_unitVehicle isKindOf "LandVehicle"):
		{
			[_unitVehicle, 40] call JB_fnc_limitSpeed;
		};
		case (_unitVehicle isKindOf "Air"):
		{
			_unitVehicle flyInHeight ((getPos _unitVehicle) select 2);
		};
	};

	private _forceUnit = [_unitVehicle, units _unitGroup] call OO_CREATE(ForceUnit);

	OO_GET(_category,ForceCategory,ForceUnits) pushBack _forceUnit;
	private _forceRatings = [OO_GET(_forceUnit,ForceUnit,Units), OO_GET(_category,ForceCategory,RatingsEast)] call SPM_Force_GetForceRatings;

	if (count _forceRatings == 0) then
	{
		diag_log format ["SPM_Armor_CreateUnit: no force rating available for %1.  Created unit not charged against category reserves.", _type];
	}
	else
	{
		private _reserves = OO_GET(_category,ForceCategory,Reserves) - OO_GET(_forceRatings select 0,ForceRating,Rating);
		OO_SET(_category,ForceCategory,Reserves,_reserves);
	};

	_forceUnit
};

OO_TRACE_DECL(SPM_Armor_CallUp) =
{
	params ["_position", "_direction", "_category", "_type"];

	private _pendingCallups = OO_GET(_category,ForceCategory,PendingCallups) - 1;
	OO_SET(_category,ForceCategory,PendingCallups,_pendingCallups);

	if (OO_GET(_category,ForceCategory,_Surrendered)) exitWith {};

	private _forceUnit = [_category, _position, _direction, _type] call SPM_Armor_CreateUnit;
	[_category, group (OO_GET(_forceUnit,ForceUnit,Units) select 0)] call SPM_Armor_Task_Patrol;

	[OO_GET(_forceUnit,ForceUnit,Vehicle), 20, 10, 20] call SPM_Util_WaitForVehicleToMove;

	if (not alive OO_GET(_forceUnit,ForceUnit,Vehicle) || { _position distance OO_GET(_forceUnit,ForceUnit,Vehicle) < 10 }) exitWith
	{
		[_category, _forceUnit] call SPM_Force_SalvageForceUnit;
	};

};

OO_TRACE_DECL(SPM_Armor_Create) =
{
	params ["_category", "_area"];

	OO_SET(_category,ForceCategory,Area,_area);
	OO_SET(_category,ForceCategory,RatingsWest,SPM_Armor_RatingsWestAPCs+SPM_Armor_RatingsWestTanks);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_Armor_RatingsEastAPCs+SPM_Armor_RatingsEastTanks);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_Armor_CallupsEastAPCs+SPM_Armor_CallupsEastTanks);
};

OO_TRACE_DECL(SPM_Armor_Delete) =
{
	params ["_category"];

	private _sideWest = OO_GET(_category,ForceCategory,SideWest);

	private _forceUnits = OO_GET(_category,ForceCategory,ForceUnits);
	[_forceUnits, _sideWest] call SPM_Armor_RemoveCapturedForceUnits;

	[] call OO_METHOD_PARENT(_category,Root,Delete,ForceCategory);
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

	{
		[_x] call SPM_DeletePatrolWaypoints;
	} forEach ([] call OO_METHOD(_dutyUnit,ForceUnit,GetGroups));

	_dutyUnit
};

OO_TRACE_DECL(SPM_Armor_EndTemporaryDuty) =
{
	params ["_category", "_forceUnit"];

	private _dutyUnits = OO_GET(_category,ArmorCategory,DutyUnits);
	private _forceUnitGroups = [] call OO_METHOD(_forceUnit,ForceUnit,GetGroups);

	private _index = -1;
	{ private _groups = [] call OO_METHOD(_x,ForceUnit,GetGroups); if (count _groups != count (_groups - _forceUnitGroups)) exitWith { _index = _forEachIndex } } forEach _dutyUnits;

	if (_index == -1) exitWith { diag_log format ["SPM_Armor_EndTemporaryDuty: unknown duty unit: %1", _forceUnit] };

	OO_GET(_forceUnit,ForceUnit,Vehicle) setVariable ["SPM_Force_AllowRetire", nil];

	{
		[_category, _x] call SPM_Armor_Task_Patrol;
	} forEach _forceUnitGroups;

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

			// Make sure there are no speed limitations on the vehicle
			[_vehicle, -1] call JB_fnc_limitSpeed;

			// Delete vehicle if abandoned
			[_vehicle] call JB_fnc_respawnVehicleInitialize;
			[_vehicle, 300, 60, 0, true] call JB_fnc_respawnVehicleWhenAbandoned;
		};
	};
};

OO_TRACE_DECL(SPM_Armor_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,ForceCategory);

	if (OO_GET(_category,ForceCategory,_Surrendered)) exitWith {};

	private _sideWest = OO_GET(_category,ForceCategory,SideWest);

	private _forceUnits = OO_GET(_category,ForceCategory,ForceUnits);
	[_forceUnits, _sideWest] call SPM_Armor_RemoveCapturedForceUnits;
	[_forceUnits, 100, _sideWest] call SPM_Force_DeleteEnemiesOnBases;

	[_forceUnits, SPM_Armor_Retire, [_category, false]] call SPM_Force_RetireDepleted;

	// Retask any units that have succeeded in getting the crew out of their target vehicle
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
				if (currentWaypoint _group < count waypoints _group) then
				{
					_vehicle = waypointAttachedVehicle ((waypoints _group) select (currentWaypoint _group));
					if (not isNull _vehicle && { count ((crew _vehicle) select { alive _x }) == 0 }) then
					{
						[_category, _group] call SPM_Armor_Task_Patrol;
					};
				};
			};
		} forEach _forceUnits;
	};

	[_forceUnits, { not alive OO_GET(_x,ForceUnit,Vehicle) }] call SPM_Force_DeleteForceUnits; //TODO: Retire?

	private _westForce = [OO_GET(_category,ForceCategory,RangeWest)] call OO_METHOD(_category,ForceCategory,GetForceLevelsWest);
	private _eastForce = [-1] call OO_METHOD(_category,ForceCategory,GetForceLevelsEast);

	_westForce = _westForce select { canFire OO_GET(_x,ForceRating,Vehicle) };

	private _firstRebalance = OO_GET(_category,ForceCategory,_FirstRebalance);
	private _changes = [_category, _westForce, _eastForce] call SPM_Force_Rebalance;

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

	if (diag_tickTime > _callupTime) then
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
			if (_firstRebalance) then
			{
				private _positions = [_center, _innerRadius, _outerRadius, OO_GET(_category,ForceCategory,SideWest)] call SPM_Util_GetInteriorSpawnPositions;

				{
					if (count _positions == 0) exitWith {};

					private _position = _positions deleteAt (floor random count _positions);

					[_position, random 360, SPM_Armor_CallUp, [_category, _x select 0]] call OO_METHOD(_spawnManager,SpawnManager,ScheduleSpawn);

					private _pendingCallups = OO_GET(_category,ForceCategory,PendingCallups) + 1;
					OO_SET(_category,ForceCategory,PendingCallups,_pendingCallups);
				} forEach CHANGES(_changes,callup);
			}
			else
			{
				private _approachDirection = OO_GET(_category,ForceCategory,CallupDirection);

				private _groundSpawnpoint = [OO_GET(_strongpoint,Strongpoint,Position), OO_GET(_strongpoint,Strongpoint,ActivityRadius), _center, _outerRadius, OO_GET(_category,ForceCategory,SideWest), _approachDirection select 0, _approachDirection select 1] call SPM_Util_GetRoadSpawnpoint;
				if (count (_groundSpawnpoint select 0) == 0) then { _groundSpawnpoint = [OO_GET(_strongpoint,Strongpoint,Position), OO_GET(_strongpoint,Strongpoint,ActivityRadius), OO_GET(_category,ForceCategory,SideWest), _approachDirection select 0, _approachDirection select 1] call SPM_Util_GetGroundSpawnpoint };

				private _airSpawnpoints = [];
				for "_i" from 1 to 3 do
				{
					_airSpawnpoints pushBack ([OO_GET(_strongpoint,Strongpoint,Position), OO_GET(_strongpoint,Strongpoint,ActivityRadius), 1500, 100 + random 100, _approachDirection select 0, _approachDirection select 1] call SPM_Util_GetAirSpawnpoint);
				};

				{
					private _spawnpoint = if ((_x select 0) isKindOf "Air") then { selectRandom _airSpawnpoints } else { _groundSpawnpoint };
					[_spawnpoint select 0, _spawnpoint select 1, SPM_Armor_CallUp, [_category, _x select 0]] call OO_METHOD(_spawnManager,SpawnManager,ScheduleSpawn);

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
	OO_DEFINE_METHOD(ArmorCategory,CreateUnit,SPM_Armor_CreateUnit);
	OO_DEFINE_METHOD(ArmorCategory,BeginTemporaryDuty,SPM_Armor_BeginTemporaryDuty);
	OO_DEFINE_METHOD(ArmorCategory,EndTemporaryDuty,SPM_Armor_EndTemporaryDuty);
	OO_DEFINE_PROPERTY(ArmorCategory,PatrolType,"STRING","area"); // area, target
	OO_DEFINE_PROPERTY(ArmorCategory,DutyUnits,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ArmorCategory,_CallupTime,"SCALAR",0);
	OO_DEFINE_PROPERTY(ArmorCategory,CallupInterval,"ARRAY",CALLUP_INTERVAL);
	OO_DEFINE_PROPERTY(ArmorCategory,_RetireTime,"SCALAR",0);
	OO_DEFINE_PROPERTY(ArmorCategory,RetireInterval,"ARRAY",RETIRE_INTERVAL);
OO_END_SUBCLASS(ArmorCategory);