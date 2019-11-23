/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

//TODO: Restructure the building occupy data so that the groups (the first array) are associated with a generic key (e.g. infantry garrison category) instead of a side index.  That allows multiple garrisons of the same side to overlap use of a single building.

// Building occupy data: [[group-east,group-west,group-independent,group-civilian], [[soldier, position, index], [soldier, position, index], ...]]
// Group occupy data: [building-occupying]

// AI have a certain chance of going active per shot heard, depending on these numbers.  Shots between MIN_DISTANCE and MAX_DISTANCE are considered (SUPPRESSED if suppressed weapon).  The distance is mapped to
// a corresponding PROBABILITY which is then raised to a given POWER.  A POWER of 1 produces a linear interpolation between MIN and MAX probabilities, a POWER of 2 produces a squared interpolation, etc.

//TODO: Currently variables so they can be tuned interactively.  Should be #defines
UNCHAIN_MIN_DISTANCE = 2;
UNCHAIN_MIN_PROBABILITY = 1.0;
UNCHAIN_MAX_DISTANCE = 40;
UNCHAIN_MAX_PROBABILITY = 0.1;
UNCHAIN_POWER = 2.0;

UNCHAIN_MAX_DISTANCE_SUPPRESSED = 8;

OO_TRACE_DECL(SPM_Occupy_SideToNumber) =
{
	[east, west, independent, civilian] find (_this select 0)
};

// The number of building positions and the number of people in the building
OO_TRACE_DECL(SPM_Occupy_OccupationCounts) =
{
	params ["_building"];

	private _occupyData = _building getVariable "SPM_Occupy_Data";

	[if (isNil "_occupyData") then { count (_building buildingPos -1) } else { count (_occupyData select 1) }, count ([_building, nil] call SPM_Occupy_GetOccupiers)]
};

OO_TRACE_DECL(SPM_Occupy_GetOccupiers) =
{
	params ["_building", "_side"];

	private _occupyData = _building getVariable "SPM_Occupy_Data";

	if (isNil "_occupyData") exitWith { [] };

	private _occupiers = [];
	{
		if (alive (_x select 0) && { isNil "_side" || { side group (_x select 0) == _side } }) then { _occupiers pushBack [_x select 0, _forEachIndex] };
	} forEach (_occupyData select 1);

	_occupiers
};

OO_TRACE_DECL(SPM_Occupy_BuildingIsOccupied) =
{
	params ["_building", "_side"];

	(count ([_building, [_side, nil] select (isNil "_side")] call SPM_Occupy_GetOccupiers)) > 0
};

OO_TRACE_DECL(SPM_Occupy_SetBuildingData) =
{
	params ["_building", "_positions"];

	private _index = -1;
	_occupyData = [[grpNull, grpNull, grpNull, grpNull], _positions apply { _index = _index + 1; [objNull, _x, _index] }];
	_building setVariable ["SPM_Occupy_Data", _occupyData];
};

OO_TRACE_DECL(SPM_Occupy_GetBuildingData) =
{
	params ["_building"];

	private _occupyData = _building getVariable "SPM_Occupy_Data";
	if (isNil "_occupyData") then
	{
		[_building, _building buildingPos -1] call SPM_Occupy_SetBuildingData;
		_occupyData = _building getVariable "SPM_Occupy_Data";
	};

	_occupyData
};

OO_TRACE_DECL(SPM_Occupy_OccupierBuilding) =
{
	params ["_unit"];

	private _unitOccupyData = _unit getVariable "SPM_Occupy_Data";
	if (isNil "_unitOccupyData") exitWith { objNull };

	_unitOccupyData select 0
};

OO_TRACE_DECL(SPM_Occupy_ReplaceOccupier) =
{
	params ["_unit", "_replacement"];

	private _unitOccupyData = _unit getVariable "SPM_Occupy_Data";
	if (isNil "_unitOccupyData") exitWith { diag_log "SPM_Occupy_ReplaceOccupier: unit has no occupy data"; false };

	private _building = _unitOccupyData select 0;
	private _buildingOccupyData = _building getVariable "SPM_Occupy_Data";

	private _index = (_buildingOccupyData select 1) findIf { _x select 0 == _unit };
	if (_index == -1) exitWith { diag_log "SPM_Occupy_ReplaceOccupier: unit points at building that doesn't point back"; false };

	(_buildingOccupyData select 1) select _index set [0, _replacement];

	_replacement setVariable ["SPM_Occupy_Data", _unitOccupyData];
	_unit setVariable ["SPM_Occupy_Data", nil];

	[_unit] join grpNull;
	[_replacement] call SPM_Occupy_JoinBuildingGroup;
	[_replacement] call SPM_Occupy_ChainUnit;

	true
};

OO_TRACE_DECL(SPM_Occupy_GetAllocatedBuilding) =
{
	params ["_unit"];

	private _unitOccupyData = _unit getVariable "SPM_Occupy_Data";
	if (isNil "_unitOccupyData") exitWith { objNull };

	_unitOccupyData select 0
};

OO_TRACE_DECL(SPM_Occupy_GetAllocatedBuildingEntry) =
{
	params ["_unit"];

	private _unitOccupyData = _unit getVariable "SPM_Occupy_Data";
	if (isNil "_unitOccupyData") exitWith { [] };

	private _buildingOccupyData = [_unitOccupyData select 0] call SPM_Occupy_GetBuildingData;

	private _index = (_buildingOccupyData select 1) findIf { (_x select 0) == _unit };
	if (_index == -1) exitWith { diag_log "ERROR: SPM_Occupy_GetAllocatedBuildingEntry encountered a soldier pointing at a building that wasn't pointing back at him."; [] };

	_buildingOccupyData select 1 select _index
};

OO_TRACE_DECL(SPM_Occupy_AllocateBuildingEntry) =
{
	params ["_building", "_unit"];

	[_unit] call SPM_Occupy_FreeBuildingEntry;

	private _occupyData = [_building] call SPM_Occupy_GetBuildingData;

	private _emptyPositions = (_occupyData select 1) select { not alive (_x select 0) };
	if (count _emptyPositions == 0) exitWith { [] };

	// Put the soldier into the list of building positions
	_unit setVariable ["SPM_Occupy_Data", [_building]];
	private _emptyPosition = selectRandom _emptyPositions;
	_emptyPosition set [0, _unit];

	_emptyPosition
};

OO_TRACE_DECL(SPM_Occupy_FreeBuildingEntry) =
{
	params ["_unit"];

	private _unitOccupyData = _unit getVariable "SPM_Occupy_Data";
	if (isNil "_unitOccupyData") exitWith { false };

	private _building = _unitOccupyData select 0;
	private _occupyData = [_building] call SPM_Occupy_GetBuildingData;

	// Null the soldier's entry
	private _entries = _occupyData select 1;
	private _index = _entries findIf { _x select 0 == _unit };
	_entries select _index set [0, objNull];

	// Delete the soldier data
	_unit setVariable ["SPM_Occupy_Data", nil];

	true
};

OO_TRACE_DECL(SPM_Occupy_UnchainUnit) =
{
	params ["_unit"];

	_unit enableAI "path";

	_unit removeEventHandler ["Hit", _unit getVariable ["SPM_Occupy_HitHandler", -1]];
	_unit setVariable ["SPM_Occupy_HitHandler", nil];
	_unit removeEventHandler ["FiredNear", _unit getVariable ["SPM_Occupy_FiredNearHandler", -1]];
	_unit setVariable ["SPM_Occupy_FiredNearHandler", nil];
};

OO_TRACE_DECL(SPM_Occupy_UncommandedExit) =
{
	params ["_unit"];

	private _building = (_unit getVariable "SPM_Occupy_Data") select 0;

	[_unit] call SPM_Occupy_UnchainUnit;
	[_unit] call SPM_Occupy_LeaveBuildingGroup;
	[_unit] call SPM_Occupy_FreeBuildingEntry;

	if ([_unit, "SPM_Occupy_UncommandedExit"] call JB_fnc_eventExists) then { [_unit, "SPM_Occupy_UncommandedExit", [_building]] call JB_fnc_eventFire };
};

SPM_Occupy_ChainUnit_FiredNearHandler =
{
	params ["_unit", "", "_distance", "", "_weapon", "", "", "_gunner"];

	if (_distance > UNCHAIN_MAX_DISTANCE) exitWith {};

	if (side _gunner == side _unit) exitWith {};

	if (_weapon == "Throw") exitWith {};

	private _detectDistance = UNCHAIN_MAX_DISTANCE;
	if (currentWeapon _gunner == _weapon && { _gunner weaponAccessories currentweapon _gunner select 0 != "" }) then { _detectDistance = UNCHAIN_MAX_DISTANCE_SUPPRESSED };

	if (_distance > _detectDistance) exitWith {};

	if (random 1 > linearConversion [UNCHAIN_MIN_DISTANCE, _detectDistance, _distance, UNCHAIN_MIN_PROBABILITY, UNCHAIN_MAX_PROBABILITY, true] ^ UNCHAIN_POWER) exitWith {};

	[_unit] call SPM_Occupy_UncommandedExit
};

//NOTE: Don't do this before calling JoinBuildingGroup because it's possible for the unit to consider itself 'hit'
// during this process, causing the unit to try to leave a building it hasn't joined.
OO_TRACE_DECL(SPM_Occupy_ChainUnit) =
{
	params ["_unit"];

	_unit disableAI "path";

	private _hitHandler = _unit addEventHandler ["Hit", SPM_Occupy_UncommandedExit];
	_unit setVariable ["SPM_Occupy_HitHandler", _hitHandler];

	private _firedNearHandler = _unit addEventHandler ["FiredNear", SPM_Occupy_ChainUnit_FiredNearHandler];
	_unit setVariable ["SPM_Occupy_FiredNearHandler", _firedNearHandler];
};

OO_TRACE_DECL(SPM_Occupy_JoinBuildingGroup) =
{
	params ["_unit"];

	private _occupyData = _unit getVariable "SPM_Occupy_Data";
	if (isNil "_occupyData") exitWith { diag_log "SPM_Occupy_JoinBuildingGroup: unit has no occupy data" };

	private _building = _occupyData select 0;
	private _buildingData = [_building] call SPM_Occupy_GetBuildingData;

	// Create a group for the side of soldier if not already present
	private _groups = _buildingData select 0;
	private _sideIndex = [side _unit] call SPM_Occupy_SideToNumber;
	if (isNull (_groups select _sideIndex)) then
	{
		private _group = createGroup (side _unit);

		_group setBehaviour (behaviour _unit);
		_group setCombatMode (combatMode _unit);
		_group setSpeedMode (speedMode _unit);

		_groups set [_sideIndex, _group];
	};

	[_unit] join (_groups select _sideIndex);
};

OO_TRACE_DECL(SPM_Occupy_LeaveBuildingGroup) =
{
	params ["_unit"];

	private _occupyData = _unit getVariable "SPM_Occupy_Data";
	if (isNil "_occupyData") exitWith { diag_log "SPM_Occupy_LeaveBuildingGroup: Unit has no occupy data" };

	private _building = _occupyData select 0;
	private _buildingData = [_building] call SPM_Occupy_GetBuildingData;

	private _groups = _buildingData select 0;
	private _entries = _buildingData select 1;
	private _sideIndex = [side _unit] call SPM_Occupy_SideToNumber;
	private _group = _groups select _sideIndex;

	// Leave the group
	[_unit] join grpNull;

	// If the group the unit left is now empty of living units, delete the group
	if ({ alive _x } count units _group == 0) then { deleteGroup _group };

	// If the building data just went empty, remove the building variable
	if ({ not isNull _x } count _groups == 0 && { { not isNull (_x select 0) } count _entries == 0 }) then { _building setVariable ["SPM_Occupy_Data", nil] };

	true
};

OO_TRACE_DECL(SPM_Occupy_CompleteOccupation) =
{
	params ["_unit"];

	private _occupyData = _unit getVariable "SPM_Occupy_Data";
	if (isNil "_occupyData") exitWith { diag_log "SPM_Occupy_CompleteOccupation: unit has no occupy data" };

	if (not alive _unit) exitWith { [_unit] call SPM_Occupy_FreeBuildingEntry };

	[group _unit] call SPM_StopWaypointMonitor;

//	_unit setUnitPos "auto";

	[_unit] call SPM_Occupy_JoinBuildingGroup;
	[_unit] call SPM_Occupy_ChainUnit;

	//BUG: ARMA seems to send units to the building's origin instead of the requested building position.  So when each
	// unit arrives, we make sure they're where they need to be.
	private _building = _occupyData select 0;
	private _buildingData = [_building] call SPM_Occupy_GetBuildingData;
	private _buildingEntries = _buildingData select 1;
	private _index = _buildingEntries findIf { _x select 0 == _unit };
	private _destination = _buildingEntries select _index select 1;
	if (_unit distance (getPos _building) < 1.0) then { _unit setPos _destination };

	// This is to ensure that an object that is used to serve as an occupy point is visible once the first unit
	// is garrisoned there.  Infantry garrisons use a campfire which the garrison code hides when created.
	if (isObjectHidden _building) then
	{
		_building hideObjectGlobal false;
		if (call SERVER_IsNightOperation) then { _building inflame true };
	};

	private _watchDirection = random 360;
	private _watchDistance = 100;
	_unit doWatch (getPos _unit vectorAdd [sin _watchDirection * _watchDistance, cos _watchDirection * _watchDistance, 0]);
};

OO_TRACE_DECL(SPM_Occupy_IsOccupyingUnit) =
{
	params ["_unit"];

	not isNil { _unit getVariable "SPM_Occupy_Data" }
};

OO_TRACE_DECL(SPM_Occupy_GetOccupierBuilding) =
{
	params ["_unit"];

	private _occupyData = _unit getVariable "SPM_Occupy_Data";
	if (isNil "_occupyData") exitWith { objNull };

	_occupyData select 0
};

// Dispatch one soldier to enter a building at a random open building position (unless the soldier already has an allocated building position)
OO_TRACE_DECL(SPM_Occupy_ApproachBuilding_Unit) =
{
	params ["_unit", "_building", ["_onArrival", {}, [{}]]];

	if (not alive _unit) exitWith { false };

	private _buildingEntry = [];

	private _allocatedBuilding = [_unit] call SPM_Occupy_GetAllocatedBuilding;
	if (isNull _allocatedBuilding) then
	{
		_buildingEntry = [_building, _unit] call SPM_Occupy_AllocateBuildingEntry;
	}
	else
	{
		if (_allocatedBuilding == _building) then
		{
			_buildingEntry = [_unit] call SPM_Occupy_GetAllocatedBuildingEntry;
		}
		else
		{
			diag_log "ERROR: SPM_Occupy_ApproachBuilding_Unit: encountered soldier approaching building that had already allocated an entry in another building.";
			[_unit] call SPM_Occupy_FreeBuildingEntry;
			_buildingEntry = [_building, _unit] call SPM_Occupy_AllocateBuildingEntry;
		};
	};

	if (count _buildingEntry == 0) exitWith { false };

	private _soloGroup = createGroup side _group;

	_soloGroup setBehaviour (behaviour _unit);
	_soloGroup setCombatMode (combatMode _unit);
	_soloGroup setSpeedMode (speedMode _unit);

	[_unit] join _soloGroup;

	private _waypoint = [_soloGroup, _buildingEntry select 1] call SPM_AddPatrolWaypoint;
	_waypoint setWaypointType "move";
	_waypoint setWaypointHousePosition (_buildingEntry select 2);
	_waypoint waypointAttachObject _building;
	[_waypoint, { [_this select 0] call SPM_Occupy_CompleteOccupation }] call SPM_AddPatrolWaypointStatements;
	[_waypoint, _onArrival] call SPM_AddPatrolWaypointStatements;

	[_soloGroup] call SPM_StartWaypointMonitor;

	true
};

// Callback when a soldier from a group arrives at his building location and it's time for the next member of the group to enter
OO_TRACE_DECL(SPM_Occupy_ApproachBuilding_Group_OnArrival) =
{
	params ["_unit"];

	[_unit getVariable "SPM_OriginalGroup", [_unit] call SPM_Occupy_GetAllocatedBuilding] call SPM_Occupy_ApproachBuilding_Group;

	_unit setVariable ["SPM_OriginalGroup", nil];
};

// Have a member of the group approach and enter the building.  When done, we'll get called back so we can send another member in.
OO_TRACE_DECL(SPM_Occupy_ApproachBuilding_Group) =
{
	params ["_group", "_building"];

	private _units = units _group;
	if (count _units == 0) exitWith { deleteGroup _group };

	private _unit = _units select (count _units - 1);
	_unit setVariable ["SPM_OriginalGroup", _group];

	[_unit, _building, SPM_Occupy_ApproachBuilding_Group_OnArrival] call SPM_Occupy_ApproachBuilding_Unit;
};

OO_TRACE_DECL(SPM_Occupy_GetBuildingExits) =
{
	params ["_building"];

	private _exits = [];
	for "_i" from 0 to 1e3 do
	{
		private _exit = _building buildingExit _i;
		if (_exit isEqualTo [0,0,0]) exitWith {};
		_exit set [2, 0]; // Exits sometimes reported below ground level
		_exits pushBack _exit;
	};

	if (count _exits == 0) then { _exits = [getPos _building] };

	_exits
};

OO_TRACE_DECL(SPM_Occupy_EnterBuilding) =
{
	params ["_group", "_building", "_method"];

	switch (_method) do
	{
		// Split up and enter the building
		case "simultaneous":
		{
			private _waypoint = _group addWaypoint [getPos _building, 0];
			_waypoint setWaypointFormation "diamond";

			[_group, _building] spawn
			{
				params ["_group", "_building"];

				scriptName "SPM_Occupy_EnterBuilding";

				{
					[_x, _building] call SPM_Occupy_ApproachBuilding_Unit;
					sleep 0.1;
				} forEach ((units _group) select { alive _x });

				if (count units _group == 0) then { deleteGroup _group };
			};

			true
		};

		// One group member enters the building at a time
		case "series":
		{
			private _waypoint = _group addWaypoint [getPos _building, 0];
			_waypoint setWaypointFormation "diamond";

			[_group, _building] call SPM_Occupy_ApproachBuilding_Group;

			true
		};

		// The group members are teleported into place in the building
		case "instant":
		{
			{
				private _unit = _x;

				private _buildingEntry = [_unit] call SPM_Occupy_GetAllocatedBuildingEntry;
				if (count _buildingEntry == 0) then { _buildingEntry = [_building, _unit] call SPM_Occupy_AllocateBuildingEntry };
				if (count _buildingEntry == 0) exitWith {};

				[_unit, _buildingEntry select 1] call SPM_Util_SetPosition;

				[_unit] call SPM_Occupy_CompleteOccupation;
			} forEach +(units _group);

			true
		};

		default { false };
	};
};
