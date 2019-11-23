/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_AmmoDumpCategory_DetonateExplosives) =
{
	_this spawn
	{
		params ["_positions", "_duration"];

		scriptName "SPM_AmmoDumpCategory_DetonateExplosives";

		private _explosives = [] call JB_fnc_detonateGetExplosives;
		private _major = _explosives select 0;
		private _primaries = _explosives select [1, 1e3];
		private _secondaries = _primaries select { (_x select 0) <= 40 };

		// Set off a large explosion at each box
		{
			[_primaries select 0, _x] call JB_fnc_detonateExplosive;
		} forEach _positions;

		// Pause
		sleep (1.0 + random 1.0);

		// Set off the really big explosion once
		[_major, _positions select 0] call JB_fnc_detonateExplosive;

		// Followed by a bunch of additional explosions over time
		private _startTime = diag_tickTime;
		private _elapsedTime = 0;

		private _primaryDelay = 2^-4;
		private _nextPrimary = 0;

		private _secondaryDelay = 0.5;	
		private _nextSecondary = 0;

		while { _elapsedTime < _duration } do
		{
			if (_elapsedTime >= _nextPrimary) then
			{
				_explosive = _primaries select (floor random [1, (_elapsedTime / _duration) * count _primaries, count _primaries]);
				[_explosive, selectRandom _positions] call JB_fnc_detonateExplosive;
				_primaryDelay = _primaryDelay * 2;
				_nextPrimary = _elapsedTime + _primaryDelay;
			};

			if (_elapsedTime >= _nextSecondary  && count _secondaries > 0) then
			{
				_explosive = selectRandom _secondaries;
				[_explosive, selectRandom _positions] call JB_fnc_detonateExplosive;
				_secondaryDelay = _secondaryDelay * 1.1;
				_nextSecondary = _elapsedTime + _secondaryDelay;
			};

			sleep 0.1;
			_elapsedTime = diag_tickTime - _startTime;
		};
	};
};

OO_TRACE_DECL(SPM_AmmoDumpCategory_DetonateAmmoDump) =
{
	params ["_category"];

	private _triggerObject = OO_GET(_category,AmmoDumpCategory,TriggerObject);
	deleteVehicle _triggerObject;

	private _explosivesObjects = OO_GET(_category,AmmoDumpCategory,_ExplosivesObjects);

	private _positions = _explosivesObjects apply { getPos _x };
	private _averagePosition = [0,0,0]; { _averagePosition = _averagePosition vectorAdd _x } forEach _positions; _averagePosition = _averagePosition vectorMultiply (1 / count _positions);

	{ deleteVehicle _x } forEach _explosivesObjects;

	// Fire burns for 100-120 seconds
	private _remains = createVehicle ["Land_GarbagePallet_F", _averagePosition, [], 0, "can_collide"];
	[_remains, [0,0,0], 100 + random 20, { deleteVehicle (_this select 0) }, _remains] call JB_fnc_fire;

	// Explosions for 20-30 seconds
	[_positions, 20 + random 10] call SPM_AmmoDumpCategory_DetonateExplosives;
};

OO_TRACE_DECL(SPM_AmmoDumpCategory_BarrelKilled) =
{
	params ["_barrel"];

	private _category = _barrel getVariable "SPM_AmmoDumpCategory_Category";
	[] call OO_METHOD(_category,AmmoDumpCategory,DetonateAmmoDump);
};

OO_TRACE_DECL(SPM_AmmoDumpCategory_CreateAmmoDumpObjects) =
{
	params ["_position", "_direction", "_enclosureObjects", "_explosivesObjects", "_triggerObjects"];

	private _objectPosition = [];

	//TODO: Walls should be simple objects
	_objectPosition = _position vectorAdd ([[2,3.7,0], _direction] call SPM_Util_RotatePosition2D);
	_enclosureObjects pushBack (["Land_HBarrier_5_F", _objectPosition, _direction] call SPM_fnc_spawnVehicle);
	
	_objectPosition = _position vectorAdd ([[2,-3.7,0], _direction] call SPM_Util_RotatePosition2D);
	_enclosureObjects pushBack (["Land_HBarrier_5_F", _objectPosition, _direction] call SPM_fnc_spawnVehicle);

	_objectPosition = _position vectorAdd ([[4.1,0,0], _direction] call SPM_Util_RotatePosition2D);
	_enclosureObjects pushBack (["Land_HBarrier_5_F", _objectPosition, _direction + 90] call SPM_fnc_spawnVehicle);

	_objectPosition = _position vectorAdd ([[-5,0,0], _direction] call SPM_Util_RotatePosition2D);
	_enclosureObjects pushBack (["Land_HBarrier_5_F", _objectPosition, _direction + 90] call SPM_fnc_spawnVehicle);


	_objectPosition = _position vectorAdd ([[-1.7,2.8,0], _direction] call SPM_Util_RotatePosition2D);
	_enclosureObjects pushBack (["Land_HBarrier_3_F", _objectPosition, _direction + 90] call SPM_fnc_spawnVehicle);

	_objectPosition = _position vectorAdd ([[-1.7,-2.8,0], _direction] call SPM_Util_RotatePosition2D);
	_enclosureObjects pushBack (["Land_HBarrier_3_F", _objectPosition, _direction + 90] call SPM_fnc_spawnVehicle);


	_objectPosition = _position vectorAdd ([[0.0,0.0,0], _direction] call SPM_Util_RotatePosition2D);
	_enclosureObjects pushBack (["CamoNet_INDP_big_F", _objectPosition, _direction] call SPM_fnc_spawnVehicle);

	{ _x enableSimulationGlobal false } forEach _enclosureObjects;


	private _boxType = "";
	private _boxTypes = ["Land_PaperBox_closed_F", "Land_PaperBox_open_full_F", "Land_PaperBox_open_empty_F", "Land_Pallet_MilBoxes_F"];

	_objectPosition = _position vectorAdd ([[2.5,2.1,0], _direction] call SPM_Util_RotatePosition2D);
	_explosivesObjects pushBack (["Land_PaperBox_closed_F", _objectPosition, _direction] call SPM_fnc_spawnVehicle);

	_boxType = selectRandom _boxTypes;
	_objectPosition = _position vectorAdd ([[0.9,2.1,0], _direction] call SPM_Util_RotatePosition2D);
	_explosivesObjects pushBack ([_boxType, _objectPosition, _direction] call SPM_fnc_spawnVehicle);

	_boxType = selectRandom _boxTypes;
	_objectPosition = _position vectorAdd ([[0.9,0.6,0], _direction] call SPM_Util_RotatePosition2D);
	_explosivesObjects pushBack ([_boxType, _objectPosition, _direction] call SPM_fnc_spawnVehicle);

	_boxType = selectRandom _boxTypes;
	_objectPosition = _position vectorAdd ([[0.9,-2.1,0], _direction] call SPM_Util_RotatePosition2D);
	_explosivesObjects pushBack ([_boxType, _objectPosition, _direction] call SPM_fnc_spawnVehicle);

	{ _x enableSimulationGlobal false } forEach _explosivesObjects;

	_boxType = "CargoNet_01_box_F";
	_objectPosition = _position vectorAdd ([[2.5,0.6,0], _direction] call SPM_Util_RotatePosition2D);
	_explosivesObjects pushBack ([_boxType, _objectPosition, _direction] call SPM_fnc_spawnVehicle);

	private _container = _explosivesObjects select (count _explosivesObjects - 1);
	private _capacity = getNumber (configFile >> "CfgVehicles" >> typeOf _container >> "maximumLoad");
	[_container, _capacity, true] call SERVER_Supply_StockAmmunitionContainer;
	[_container, SERVER_Magazines_MAAWSToRPG, []] call JB_fnc_containerSubstitute;

	_boxType = "CargoNet_01_box_F";
	_objectPosition = _position vectorAdd ([[2.5,-2.1,0], _direction] call SPM_Util_RotatePosition2D);
	_explosivesObjects pushBack ([_boxType, _objectPosition, _direction] call SPM_fnc_spawnVehicle);

	private _container = _explosivesObjects select (count _explosivesObjects - 1);
	private _capacity = getNumber (configFile >> "CfgVehicles" >> typeOf _container >> "maximumLoad");
	[_container, _capacity, true] call SERVER_Supply_StockExplosivesContainer;

	_objectPosition = _position vectorAdd ([[2.5,-0.8,0], _direction] call SPM_Util_RotatePosition2D);
	_triggerObjects pushBack (["Land_MetalBarrel_F", _objectPosition, _direction] call SPM_fnc_spawnVehicle);

	[_triggerObjects select (count _triggerObjects - 1), "CAD", "AMMO DUMP"] call TRACE_SetObjectString;
};

OO_TRACE_DECL(SPM_AmmoDumpCategory_CreateAmmoDump) =
{
	params ["_category"];

	private _area = OO_GET(_category,AmmoDumpCategory,Area);
	private _center = OO_GET(_area,StrongpointArea,Position);
	private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _positions = [];
	while { true } do
	{
		// Find a spot clear of this stuff
		_positions = [_center, _innerRadius, _outerRadius, 10] call SPM_Util_SampleAreaGrid;
		[_positions, ["#GdtRoad", "#GdtWater", "#GdtConcrete"]] call SPM_Util_ExcludeSamplesBySurfaceType;
		[_positions, 20, 90] call SPM_Util_ExcludeSamplesBySurfaceIncline;
		[_positions, 6.0, ["FENCE", "WALL", "BUILDING", "HOUSE", "ROCK", "ROAD"]] call SPM_Util_ExcludeSamplesByProximity;

		if (count _positions > 0) exitWith {};

		diag_log format ["SPM_AmmoDumpCategory_CreateAmmoDump: Unable to create ammo dump %1, %2, %3", _center, _innerRadius, _outerRadius];
		_innerRadius = _outerRadius;
		_outerRadius = _outerRadius + 50;
	};

	if (count _positions == 0) exitWith { };

	private _position = [_positions, _center] call SPM_Util_ClosestPosition;

	// Remove miscellaneous items
	private _blockingObjects = nearestTerrainObjects [_position, ["TREE", "SMALL TREE", "BUSH", "HIDE"], 10, false, true];
	{
		_x hideObjectGlobal true;
	} forEach _blockingObjects;
	OO_SET(_category,AmmoDumpCategory,_BlockingObjects,_blockingObjects);

	private _direction = [_position, 0] call SPM_Util_EnvironmentAlignedDirection;

	private _explosivesObjects = OO_GET(_category,AmmoDumpCategory,_ExplosivesObjects);
	private _enclosureObjects = OO_GET(_category,AmmoDumpCategory,_EnclosureObjects);
	private _triggerObjects = [];

	private _dumpObjects = [_position, _direction, _enclosureObjects, _explosivesObjects, _triggerObjects] call SPM_AmmoDumpCategory_CreateAmmoDumpObjects;

	private _triggerObject = _triggerObjects select 0;
	_triggerObject setVariable ["SPM_AmmoDumpCategory_Category", _category];
	_triggerObject addEventHandler ["Killed", SPM_AmmoDumpCategory_BarrelKilled];
	[_category, _triggerObject] call OO_GET(_category,Category,InitializeObject);

	OO_SET(_category,AmmoDumpCategory,TriggerObject,_triggerObject);
};

OO_TRACE_DECL(SPM_AmmoDumpCategory_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,Category);

	if (count OO_GET(_category,AmmoDumpCategory,_EnclosureObjects) == 0) then
	{
		[_category] call SPM_AmmoDumpCategory_CreateAmmoDump;

		OO_SET(_category,Category,UpdateTime,1e30);
	};
};

OO_TRACE_DECL(SPM_AmmoDumpCategory_Delete) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Root,Delete,Category);

	private _trigger = OO_GET(_category,AmmoDumpCategory,TriggerObject);
	if (not isNull _trigger) then { deleteVehicle _trigger };

	{
		if (not isNull _x) then { deleteVehicle _x };
	} forEach OO_GET(_category,AmmoDumpCategory,_EnclosureObjects);

	{
		if (not isNull _x) then { deleteVehicle _x };
	} forEach OO_GET(_category,AmmoDumpCategory,_ExplosivesObjects);

	private _blockingObjects = OO_GET(_category,AmmoDumpCategory,_BlockingObjects);
	{
		_x hideObjectGlobal false;
	} forEach _blockingObjects;
};

OO_TRACE_DECL(SPM_AmmoDumpCategory_Create) =
{
	params ["_category", "_area"];

	OO_SET(_category,AmmoDumpCategory,Area,_area);
};

OO_BEGIN_SUBCLASS(AmmoDumpCategory,Category);
	OO_OVERRIDE_METHOD(AmmoDumpCategory,Root,Create,SPM_AmmoDumpCategory_Create);
	OO_OVERRIDE_METHOD(AmmoDumpCategory,Root,Delete,SPM_AmmoDumpCategory_Delete);
	OO_OVERRIDE_METHOD(AmmoDumpCategory,Category,Update,SPM_AmmoDumpCategory_Update);
	OO_DEFINE_METHOD(AmmoDumpCategory,DetonateAmmoDump,SPM_AmmoDumpCategory_DetonateAmmoDump);
	OO_DEFINE_PROPERTY(AmmoDumpCategory,Area,"ARRAY",[]); // StrongpointArea structure
	OO_DEFINE_PROPERTY(AmmoDumpCategory,TriggerObject,"OBJECT",objNull);
	OO_DEFINE_PROPERTY(AmmoDumpCategory,_EnclosureObjects,"ARRAY",[]);
	OO_DEFINE_PROPERTY(AmmoDumpCategory,_ExplosivesObjects,"ARRAY",[]);
	OO_DEFINE_PROPERTY(AmmoDumpCategory,_BlockingObjects,"ARRAY",[]);
OO_END_SUBCLASS(AmmoDumpCategory);
