/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

SPM_CivilianVehiclesCategory_VehicleTypes = [];

SPM_CivilianVehiclesCategory_CreateVehicle =
{
	params ["_position", "_direction"];

	if (count SPM_CivilianVehiclesCategory_VehicleTypes == 0) then
	{
		SPM_CivilianVehiclesCategory_VehicleTypes = "(configName _x) isKindOf 'Car_F'" configClasses (configFile >> "CfgVehicles");
		SPM_CivilianVehiclesCategory_VehicleTypes deleteAt 0; // Car_F
		SPM_CivilianVehiclesCategory_VehicleTypes = SPM_CivilianVehiclesCategory_VehicleTypes select { getText (_x >> "faction") == "CIV_F" && { configName _x find "Kart" == -1 } };
		SPM_CivilianVehiclesCategory_VehicleTypes = SPM_CivilianVehiclesCategory_VehicleTypes apply { configName _x };
	};

	private _vehicleType = selectRandom SPM_CivilianVehiclesCategory_VehicleTypes;

	private _vehicle = [_vehicleType, _position, _direction] call SPM_fnc_spawnVehicle;
	_vehicle lock 3;

	_vehicle
};

SPM_CivilianVehiclesCategory_ParkingPosition =
{
	params ["_position", "_range", "_selection", "_size"];

	private _roads = _position nearRoads _range;

	if (count _roads == 0) exitWith { [] };

	switch (_selection) do
	{
		case "closest":
		{
			_roads = _roads apply { [_x distanceSqr _position, _x] };
			_roads sort true;
		};

		case "random":
		{
			_roads = _roads apply { [random 1, _x] };
			_roads sort true;
		};

		default
		{
			_roads = [];
		};
	};

	private _parking = [];

	while { count _roads > 0 } do
	{
		private _road = _roads deleteAt 0 select 1;
		private _others = roadsConnectedTo _road;

		private _parkingDirection = if (count _others == 0) then { 0 } else { _road getDir (_others select 0); };

		private _toSide = [sin (_parkingDirection + 90), cos (_parkingDirection + 90), 0];
		private _toOwner = (getPos _road) vectorFromTo _position;

		if (_toSide vectorDotProduct _toOwner < 0) then
		{
			_parkingDirection = _parkingDirection + 180;
			_toSide = _toSide vectorMultiply -1;
		};

		private _parkingPosition = getPos _road;
		while { isOnRoad _parkingPosition } do { _parkingPosition = _parkingPosition vectorAdd _toSide };
		_parkingPosition = _parkingPosition vectorAdd (_toSide vectorMultiply -1);

		if ((nearestObject [_parkingPosition, "LandVehicle"]) distance _parkingPosition > _size) exitWith { _parking = [_parkingPosition, _parkingDirection] };
	};

	_parking
};

SPM_CivilianVehiclesCategory_CreateVehicles =
{
	params ["_category"];

	private _ownershipRate = OO_GET(_category,CivilianVehiclesCategory,OwnershipRate);
	private _vehicles = OO_GET(_category,CivilianVehiclesCategory,Vehicles);

	private _area = OO_GET(_category,CivilianVehiclesCategory,Area);
	private _center = OO_GET(_area,StrongpointArea,Position);
	private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _data = [];
	private _chain =
	[
		[SPM_Chain_FixedPosition, [_center]],
		[SPM_Chain_PositionToBuildings, [_innerRadius, _outerRadius]],
		[SPM_Chain_BuildingsToEnterableBuildings, []]
	];
	private _complete = [_data, _chain] call SPM_Chain_Execute;

	if (_complete) then
	{
		{
			if (random 1 < _ownershipRate && { [_x, civilian] call SPM_Occupy_BuildingIsOccupied }) then
			{
				private _parking = [getPos _x, 30, "closest", 6] call SPM_CivilianVehiclesCategory_ParkingPosition;

				if (count _parking == 2) then
				{
					_vehicles pushBack ([_parking select 0, _parking select 1] call SPM_CivilianVehiclesCategory_CreateVehicle);
				};
			};
		} forEach ([_data, "enterable-buildings"] call SPM_Util_GetDataValue);
	};

	if (count _vehicles == 0) then { _vehicles pushBack objNull };
};

SPM_CivilianVehiclesCategory_Update =
{
	params ["_category"];

	if (count OO_GET(_category,CivilianVehiclesCategory,Vehicles) == 0) then
	{
		[_category] call SPM_CivilianVehiclesCategory_CreateVehicles;
	};
};

SPM_CivilianVehiclesCategory_Delete =
{
	params ["_category"];

	{
		if (not isNull _x) then { deleteVehicle _x };
	} forEach OO_GET(_category,CivilianVehiclesCategory,Vehicles);

//	private _area = OO_GET(_category,CivilianVehiclesCategory,Area);
//	call OO_DELETE(_area);
};

SPM_CivilianVehiclesCategory_Create =
{
	params ["_category", "_area"];

	OO_SET(_category,CivilianVehiclesCategory,Area,_area);
};

OO_BEGIN_SUBCLASS(CivilianVehiclesCategory,Category);
	OO_OVERRIDE_METHOD(CivilianVehiclesCategory,Root,Create,SPM_CivilianVehiclesCategory_Create);
	OO_OVERRIDE_METHOD(CivilianVehiclesCategory,Root,Delete,SPM_CivilianVehiclesCategory_Delete);
	OO_OVERRIDE_METHOD(CivilianVehiclesCategory,Category,Update,SPM_CivilianVehiclesCategory_Update);
	OO_DEFINE_PROPERTY(CivilianVehiclesCategory,Area,"ARRAY",[]); // StrongpointArea structure
	OO_DEFINE_PROPERTY(CivilianVehiclesCategory,OwnershipRate,"SCALAR",0.4);
	OO_DEFINE_PROPERTY(CivilianVehiclesCategory,Vehicles,"ARRAY",[]);
OO_END_SUBCLASS(CivilianVehiclesCategory);
