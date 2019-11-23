/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveDestroyVehicle_CreateVehicle) =
{
	params ["_objective"];

	private _vehicleDescriptor = OO_GET(_objective,ObjectiveDestroyVehicle,VehicleDescriptor);
	private _vehicleType = _vehicleDescriptor select 0;
	private _vehicleInitializer = _vehicleDescriptor select 1;

	private _placement = OO_GET(_objective,ObjectiveDestroyVehicle,Placement);
	private _garrison = OO_NULL;
	private _area = _placement;
	if (OO_INSTANCE_ISOFCLASS(_placement,InfantryGarrisonCategory)) then
	{
		_garrison = _placement;
		_area = OO_GET(_garrison,ForceCategory,Area);
	};

	private _parkingPosition = [];
	if (not (_vehicleType isKindOf "Air")) then
	{
		private _mission = OO_GETREF(_objective,Category,Strongpoint);

		private _garrison = OO_NULL;
		{
			if (OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory)) exitWith { _garrison = _x };
		} forEach OO_GET(_mission,Strongpoint,Categories);

		private _housedUnits = OO_GET(_garrison,InfantryGarrisonCategory,HousedUnits);

		_housedUnits = +_housedUnits;

		while { count _parkingPosition == 0 && count _housedUnits > 0 } do
		{
			private _unit = _housedUnits deleteAt (floor random count _housedUnits);
			_parkingPosition = [getPos _unit, 30, "closest", 10] call SPM_CivilianVehiclesCategory_ParkingPosition;
		};
	};

	if (count _parkingPosition == 0) then
	{
		private _center = OO_GET(_area,StrongpointArea,Position);
		private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
		private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

		private _exclusions = ["WALL", "BUILDING", "HOUSE", "ROCK", "ROAD"];

		private _positions = [];
		while { _innerRadius < _outerRadius } do
		{
			_positions = [_center, _innerRadius, _innerRadius + 20, 4.0] call SPM_Util_SampleAreaGrid;
			[_positions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
			[_positions, 20, 90] call SPM_Util_ExcludeSamplesBySurfaceIncline;
			[_positions, 8.0, _exclusions] call SPM_Util_ExcludeSamplesByProximity;

			if (count _positions > 0) exitWith {};

			diag_log format ["SPM_ObjectiveDestroyVehicle_CreateVehicle: Unable to create vehicle %1, %2, %3", _center, _innerRadius, _innerRadius + 20];
			_innerRadius = _innerRadius + 20;
		};

		if (count _positions > 0) then { _parkingPosition = [[_positions, _center] call SPM_Util_ClosestPosition, random 360] };
	};

	if (count _parkingPosition == 0) exitWith
	{
		OO_SET(_objective,MissionObjective,State,"error");
		false
	};

	if (_vehicleType isKindOf "Air") then
	{
		private _blockingObjects = nearestTerrainObjects [_parkingPosition select 0, ["TREE", "SMALL TREE", "HIDE"], 30, false, true];
		OO_SET(_objective,ObjectiveDestroyVehicle,_BlockingObjects,_blockingObjects);
		{ _x hideObjectGlobal true } forEach _blockingObjects;
	};

	private _vehicle = [_vehicleType, _parkingPosition select 0, _parkingPosition select 1] call SPM_fnc_spawnVehicle;

	([_vehicle] + (_vehicleInitializer select 1)) call (_vehicleInitializer select 0);
	[_objective, _vehicle] call OO_GET(_category,Category,InitializeObject);

	_vehicle setVehicleLock "unlocked";

	OO_SET(_objective,MissionObjective,ObjectiveObject,_vehicle);

	true
};

OO_TRACE_DECL(SPM_ObjectiveDestroyVehicle_GetDescription) =
{
	params ["_objective"];

	["Destroy or capture " + OO_GET(_objective,ObjectiveDestroyObject,ObjectiveObjectDescription), "Destroy or capture the vehicle."];
};

OO_TRACE_DECL(SPM_ObjectiveDestroyVehicle_Create) =
{
	params ["_objective", "_vehicleDescriptor", "_placement"];

	OO_SET(_objective,ObjectiveDestroyVehicle,VehicleDescriptor,_vehicleDescriptor);
	OO_SET(_objective,ObjectiveDestroyVehicle,Placement,_placement);

	private _vehicleDescription = getText (configFile >> "CfgVehicles" >> (_vehicleDescriptor select 0) >> "displayName");
	OO_SET(_objective,ObjectiveDestroyObject,ObjectiveObjectDescription,_vehicleDescription);
};

OO_TRACE_DECL(SPM_ObjectiveDestroyVehicle_Delete) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Root,Delete,ObjectiveDestroyObject);

	private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);
	if (not isNull _object) then
	{
		[_object, "ODV", nil] call TRACE_SetObjectString;
		if (OO_GET(_objective,MissionObjective,State) != "succeeded") then
		{
			deleteVehicle _object;
		};
	};

	{
		_x hideObjectGlobal false;
	} forEach OO_GET(_objective,ObjectiveDestroyVehicle,_BlockingObjects);
};

OO_BEGIN_SUBCLASS(ObjectiveDestroyVehicle,ObjectiveDestroyObject);
	OO_OVERRIDE_METHOD(ObjectiveDestroyVehicle,Root,Create,SPM_ObjectiveDestroyVehicle_Create);
	OO_OVERRIDE_METHOD(ObjectiveDestroyVehicle,Root,Delete,SPM_ObjectiveDestroyVehicle_Delete);
	OO_OVERRIDE_METHOD(ObjectiveDestroyVehicle,MissionObjective,GetDescription,SPM_ObjectiveDestroyVehicle_GetDescription);
	OO_OVERRIDE_METHOD(ObjectiveDestroyVehicle,ObjectiveDestroyObject,ObjectiveObjectReady,SPM_ObjectiveDestroyVehicle_CreateVehicle);
	OO_DEFINE_PROPERTY(ObjectiveDestroyVehicle,VehicleDescriptor,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ObjectiveDestroyVehicle,Placement,"#OBJ",OO_NULL); // StrongpointArea or InfantryGarrisonCategory
	OO_DEFINE_PROPERTY(ObjectiveDestroyVehicle,_BlockingObjects,"ARRAY",[]);
OO_END_SUBCLASS(ObjectiveDestroyVehicle);
