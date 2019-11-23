/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

// When a player enters the vehicle, null out the entry in the originating armor category's ForceUnit structure, as if it had been deleted.
OO_TRACE_DECL(SPM_ArmorIdle_GetInHandler) =
{
	params ["_vehicle", "_position", "_unit", "_turret"];

	if (side _unit == west) then //TODO: Look at the WestSide of the associated armor category
	{
		private _data = _vehicle getVariable "SPM_ArmorIdle";
		_vehicle removeEventHandler ["GetIn", _data select 1];
		OO_SET(_data select 0,ForceUnit,Vehicle,objNull);
	};
};

OO_TRACE_DECL(SPM_ArmorIdle_WS_Park) =
{
	params ["_leader", "_units", "_forceUnit"];

	private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	[_vehicle, "AI", "UNLOCKED"] call TRACE_SetObjectString;
	private _getInHandler = _vehicle addEventHandler ["GetIn", SPM_ArmorIdle_GetInHandler];
	_vehicle setVariable ["SPM_ArmorIdle", [_forceUnit, _getInHandler]];
	_vehicle setVehicleLock "unlocked";
	[_vehicle, -1] call JB_fnc_limitSpeed;

	private _group = [] call OO_METHOD(_forceUnit,ForceUnit,GetGroup);

	{ unassignVehicle _x } forEach units _group;
	units _group orderGetIn false;
	units _group allowGetIn false;

	_group setSpeedMode "limited";

	private _waypoint = [_group, getPos _vehicle] call SPM_AddPatrolWaypoint;
	_waypoint setWaypointType "hold";
};

OO_TRACE_DECL(SPM_ArmorIdle_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,ForceCategory);

	private _armor = OO_GET(_category,ArmorIdleCategory,_Armor);
	private _forceUnit = [] call OO_METHOD(_armor,ArmorCategory,BeginTemporaryDuty);
	if (not isNull OO_GET(_forceUnit,ForceUnit,Vehicle)) then
	{
		private _idleUnits = OO_GET(_category,ArmorIdleCategory,_IdleUnits);
		_idleUnits pushBack _forceUnit;
		
		private _area = OO_GET(_armor,ForceCategory,Area);
		private _center = OO_GET(_area,StrongpointArea,Position);
		private _parkingPosition = [_center, 50, "random", 10] call SPM_CivilianVehiclesCategory_ParkingPosition;

		if (count _parkingPosition == 0) then { _parkingPosition = [_center, random 360] };

		private _group = [] call OO_METHOD(_forceUnit,ForceUnit,GetGroup);
		private _waypoint = [_group, _parkingPosition select 0] call SPM_AddPatrolWaypoint;
		[_waypoint, SPM_ArmorIdle_WS_Park, _forceUnit] call SPM_AddPatrolWaypointStatements;

		private _number = OO_GET(_category,ArmorIdleCategory,_Number);
		if (count _idleUnits == _number) then
		{
			OO_SET(_category,Category,UpdateTime,1e30);
		};
	};
};

OO_TRACE_DECL(SPM_ArmorIdle_Create) =
{
	params ["_category", "_armor", "_number"];

	_number = (floor _number) max 0;

	OO_SET(_category,ArmorIdleCategory,_Armor,_armor);
	OO_SET(_category,ArmorIdleCategory,_Number,_number);
	OO_SET(_category,Category,GetUpdateInterval,{2});

	if (_number == 0) then
	{
		OO_SET(_category,Category,UpdateTime,1e30);
	};
};

OO_BEGIN_SUBCLASS(ArmorIdleCategory,Category);
	OO_OVERRIDE_METHOD(ArmorIdleCategory,Root,Create,SPM_ArmorIdle_Create);
	OO_OVERRIDE_METHOD(ArmorIdleCategory,Category,Update,SPM_ArmorIdle_Update);
	OO_DEFINE_PROPERTY(ArmorIdleCategory,_Armor,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(ArmorIdleCategory,_Number,"SCALAR",0);
	OO_DEFINE_PROPERTY(ArmorIdleCategory,_IdleUnits,"ARRAY",[]);
OO_END_SUBCLASS(ArmorIdleCategory);
