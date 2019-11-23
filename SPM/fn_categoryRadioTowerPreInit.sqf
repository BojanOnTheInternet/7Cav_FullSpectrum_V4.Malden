/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_RadioTowerCategory_TowerHit) =
{
	params ["_tower", "_causedBy", "_damage", "_instigator"];

	if (_damage > 3) then
	{
		_tower setDamage 1.0;
	};
};

OO_TRACE_DECL(SPM_RadioTowerCategory_CreateRadioTower) =
{
	params ["_category"];

	private _area = OO_GET(_category,RadioTowerCategory,Area);
	private _center = OO_GET(_area,StrongpointArea,Position);
	private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _positions = [];
	while { _innerRadius <= _outerRadius } do
	{
		_positions = [_center, _innerRadius, _innerRadius + 20, 4.0] call SPM_Util_SampleAreaGrid; //TODO: Range should be based on the X/Y dimensions of _towerType
		[_positions, ["#GdtRoad", "#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
		[_positions, 10, 90] call SPM_Util_ExcludeSamplesBySurfaceIncline;
		[_positions, 4.0, ["FENCE", "WALL", "BUILDING", "HOUSE", "ROCK", "ROAD"]] call SPM_Util_ExcludeSamplesByProximity;

		if (count _positions > 0) exitWith {};

		diag_log format ["SPM_RadioTowerCategory_CreateTower: Unable to create communications tower %1, %2, %3", _center, _innerRadius, _innerRadius + 20];
		_innerRadius = _innerRadius + 20;
	};

	if (count _positions == 0) exitWith { OO_SET(_category,RadioTowerCategory,RadioTower,objNull) };

	private _towerPosition = [_positions, _center] call SPM_Util_ClosestPosition;

	// Remove miscellaneous items
	private _blockingObjects = nearestTerrainObjects [_towerPosition, ["TREE", "SMALL TREE", "BUSH", "HIDE"], 4, false, true];
	{
		_x hideObjectGlobal true;
	} forEach _blockingObjects;
	OO_SET(_category,RadioTowerCategory,_BlockingObjects,_blockingObjects);

	private _towerDirection = [_towerPosition, 0] call SPM_Util_EnvironmentAlignedDirection;

	//TODO: Instead of a tower, could put a vehicle next to the building or at the tower position
	//TODO: Ifrit antenna at [0,-2.5,0.7]
	//TODO: Strider antenna at [0,-0.2,0.9]

	private _towerType = OO_GET(_category,RadioTowerCategory,TowerType);
	private _radioTower = [_towerType, _towerPosition, _towerDirection] call SPM_fnc_spawnVehicle;
	[_category, _radioTower] call OO_GET(_category,Category,InitializeObject);

	_radioTower setVectorUp [0,0,1];  // Will rotate around the origin of the object, which is usually in its middle

	[_radioTower, "CRT", "TOWER"] call TRACE_SetObjectString;

	OO_SET(_category,RadioTowerCategory,RadioTower,_radioTower);

	true
};

OO_TRACE_DECL(SPM_RadioTowerCategory_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,Category);

	if (isNil { OO_GET(_category,RadioTowerCategory,RadioTower) }) then
	{
		[_category] call SPM_RadioTowerCategory_CreateRadioTower;

		OO_SET(_category,Category,UpdateTime,1e30);
	};
};

OO_TRACE_DECL(SPM_RadioTowerCategory_Create) =
{
	params ["_category", "_towerType", "_area"];

	OO_SET(_category,RadioTowerCategory,TowerType,_towerType);
	OO_SET(_category,RadioTowerCategory,Area,_area);
};

OO_TRACE_DECL(SPM_RadioTowerCategory_Delete) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Root,Delete,Category);

	private _object = OO_GET(_category,RadioTowerCategory,RadioTower);
	if (not isNil "_object" && { not isNull _object }) then { deleteVehicle _object };

	private _blockingObjects = OO_GET(_category,RadioTowerCategory,_BlockingObjects);
	{
		_x hideObjectGlobal false;
	} forEach _blockingObjects;
};

OO_BEGIN_SUBCLASS(RadioTowerCategory,Category);
	OO_OVERRIDE_METHOD(RadioTowerCategory,Root,Create,SPM_RadioTowerCategory_Create);
	OO_OVERRIDE_METHOD(RadioTowerCategory,Root,Delete,SPM_RadioTowerCategory_Delete);
	OO_OVERRIDE_METHOD(RadioTowerCategory,Category,Update,SPM_RadioTowerCategory_Update);
	OO_DEFINE_PROPERTY(RadioTowerCategory,TowerType,"STRING","");
	OO_DEFINE_PROPERTY(RadioTowerCategory,Area,"ARRAY",[]); // StrongpointArea structure
	OO_DEFINE_PROPERTY(RadioTowerCategory,RadioTower,"OBJECT",nil);
	OO_DEFINE_PROPERTY(RadioTowerCategory,_BlockingObjects,"ARRAY",[]);
OO_END_SUBCLASS(RadioTowerCategory);
