/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

OO_TRACE_DECL(SPM_AmmoCaches_Killed) =
{
	_this spawn
	{
		sleep (0.2 + random 0.3);
		{ deleteVehicle _x } forEach (attachedObjects (_this select 0));
		[_this select 0, false] call JB_fnc_detonateObject
	};
};

if (not isServer && hasInterface) exitWith {};

OO_TRACE_DECL(SPM_AmmoCaches_GetPlaceholderType) =
{
	params ["_side"];

	switch (_side) do
	{
		case west: { "B_soldier_F" };
		case east: { "O_soldier_F" };
		case independent: { "I_soldier_F" };
		case civilian: { "C_man_1" };
	};
};

OO_TRACE_DECL(SPM_AmmoCaches_CreateCaches) =
{
	params ["_category"];

	// Place caches in buildings where the garrison is housed

	private _buildings = [];
	{
		_buildings pushBackUnique ([_x] call SPM_Occupy_GetOccupierBuilding);
	} forEach OO_GET(_garrison,InfantryGarrisonCategory,HousedUnits);
	private _buildingsCopy = +_buildings;

	private _side = OO_GET(_garrison,ForceCategory,SideEast);
	private _placeholderType = [_side] call SPM_AmmoCaches_GetPlaceholderType;

	while { count OO_GET(_category,AmmoCachesCategory,_Caches) < OO_GET(_category,AmmoCachesCategory,_NumberCaches) && count _buildings > 0 } do
	{
		private _placeholderGroup = [_side, [[_placeholderType]], call JB_MDI_RandomSpawnPosition, 0, true] call SPM_fnc_spawnGroup;
		private _placeholder = (units _placeholderGroup) select 0;
		_placeholder hideObjectGlobal true;
		_placeholder enableSimulationGlobal false;

		private _buildingPosition = [];
		while { count _buildings > 0 } do
		{
			private _buildingIndex = floor random count _buildings;
			private _building = _buildings select _buildingIndex;

			[_placeholderGroup, _building, "instant"] call SPM_fnc_occupyEnterBuilding;
			if ([_placeholder] call SPM_Occupy_IsOccupyingUnit) exitWith { OO_GET(_category,AmmoCachesCategory,_Caches) pushBack [_placeholder, []] };

			_buildings deleteAt _buildingIndex;
		};

		if (not ([_placeholder] call SPM_Occupy_IsOccupyingUnit)) then
		{
			deleteVehicle _placeholder;
			deleteGroup _placeholderGroup;
		};
	};

	if (count OO_GET(_category,AmmoCachesCategory,_Caches) == OO_GET(_category,AmmoCachesCategory,_NumberCaches)) exitWith {};

	// Place caches near to significant places.  That will be other caches, then garrisoned buildings, then the center of the area

	private _startingPositions = OO_GET(_category,AmmoCachesCategory,_Caches) apply { getPos (_x select 0) };
	_startingPositions append (_buildingsCopy apply { getPos _x });
	
	private _area = OO_GET(_garrison,ForceCategory,Area);
	private _center = OO_GET(_area,StrongpointArea,Position);
	_startingPositions pushBack _center;

	private _nearPositions = [];

	while { count OO_GET(_category,AmmoCachesCategory,_Caches) < OO_GET(_category,AmmoCachesCategory,_NumberCaches) && count _startingPositions > 0 } do
	{
		private _startingPosition = _startingPositions deleteAt 0;

		private _remainingCaches = OO_GET(_category,AmmoCachesCategory,_NumberCaches) - count OO_GET(_category,AmmoCachesCategory,_Caches);
		private _positions = [_startingPosition, 0, 20, 3] call SPM_Util_SampleAreaGrid;
		[_positions, ["#GdtRoad", "#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
		[_positions, 20, 90] call SPM_Util_ExcludeSamplesBySurfaceIncline;
		[_positions, 0, ["BUILDING", "HOUSE", "ROCK", "WALL", "FENCE", "HIDE", "TREE"]] call SPM_Util_ExcludeSamplesByProximity;
		[_positions, 3, ["BUILDING", "HOUSE", "ROCK", "WALL"], _nearPositions] call SPM_Util_ExcludeSamplesByProximity;

		while { count OO_GET(_category,AmmoCachesCategory,_Caches) < OO_GET(_category,AmmoCachesCategory,_NumberCaches) && count _nearPositions > 0 } do
		{
			private _position = _nearPositions deleteAt (floor random count _nearPositions);
			OO_GET(_category,AmmoCachesCategory,_Caches) pushBack [_position, []];
		};
	};
};

OO_TRACE_DECL(SPM_AmmoCaches_CreateContainers) =
{
	params ["_category"];

	private _minCount = OO_GET(_category,AmmoCachesCategory,_ContainersPerCache) select 0;
	private _maxCount = OO_GET(_category,AmmoCachesCategory,_ContainersPerCache) select 1;
	private _containerTypes = OO_GET(_category,AmmoCachesCategory,_ContainerTypes);
	if ((_containerTypes select 0) isEqualType "") then { _containerTypes = [[_containerTypes, -1, false]] };

	// Add objNull containers to establish the counts
	{
		for "_i" from 1 to _minCount + (floor random (_maxCount - _minCount)) do { (_x select 1) pushBack objNull };
	} forEach OO_GET(_category,AmmoCachesCategory,_Caches);

	private _shift = 1.0;

	private _containerPosition = [];
	private _containerDirection = 0;

	// Create one container per pass for each cache
	for "_i" from 0 to _maxCount do
	{
		{
			private _index = (_x select 1) find objNull;
			if (_index >= 0) then
			{
				private _types = _containerTypes select (_i min (count _containerTypes - 1));
				(selectRandom _types) params ["_containerType", ["_containerDamage", -1, [0]], ["_containerHasMissiles", false, [true]]];

				switch (typeName (_x select 0)) do
				{
					case typeName objNull:
					{
						_containerPosition = getPosATL (_x select 0);
						_containerDirection = getdir ([_x select 0] call SPM_Occupy_GetOccupierBuilding)
					};
					case typeName []:
					{
						_containerPosition = _x select 0;
						_containerDirection = [_containerPosition, 0] call SPM_Util_EnvironmentAlignedDirection;
					};
				};
				_containerDirection = _containerDirection + (90 * floor random 4);

				private _container = [_containerType, _containerPosition vectorAdd [-_shift + random (_shift * 2), -_shift + random (_shift * 2), 2.0], _containerDirection] call SPM_fnc_spawnVehicle;
				[_container] call JB_fnc_containerClear;
				[_container] call JB_fnc_containerLock;
				[_container, _containerDamage, _containerHasMissiles] call JB_fnc_detonateSetDamage;
				_container allowDamage false;

				if (OO_GET(_category,AmmoCachesCategory,ContainersDetectable)) then { [_container, true] call OO_METHOD(_category,AmmoCachesCategory,SetContainerDetectable) };

				[_category, _container] call OO_GET(_category,Category,InitializeObject);
				[_container, 0.5, 1.0] call JB_fnc_damagePulseInitObject;

				[[_container], { (_this select 0) addEventHandler ["Killed", SPM_AmmoCaches_Killed] }] remoteExec ["call", 0, true]; // JIP

				(_x select 1) set [_index, _container];
			}
		} forEach OO_GET(_category,AmmoCachesCategory,_Caches);

		sleep 1; // Delay to let the containers drop into place
	};

	// Wait until the containers have settled down and then allow them to take damage again
	sleep 3;
	{
		{ _x allowDamage true } forEach (_x select 1);
	} forEach OO_GET(_category,AmmoCachesCategory,_Caches);
};

OO_TRACE_DECL(SPM_AmmoCaches_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,Category);

	if (count OO_GET(_category,AmmoCachesCategory,_Caches) == 0) then
	{
		private _garrison = OO_GET(_category,AmmoCachesCategory,_Garrison);
		private _initialForceCreated = OO_GET(_garrison,InfantryGarrisonCategory,InitialForceCreated);
		if (_initialForceCreated) then
		{
			[_category] call SPM_AmmoCaches_CreateCaches;
			[_category] call SPM_AmmoCaches_CreateContainers;
		};
	};
};

OO_TRACE_DECL(SPM_AmmoCaches_Create) =
{
	params ["_category", "_garrison", "_numberCaches", "_containersPerCache", "_containerTypes"];

	OO_SET(_category,Category,GetUpdateInterval,{5});

	OO_SET(_category,AmmoCachesCategory,_Garrison,_garrison);
	OO_SET(_category,AmmoCachesCategory,_NumberCaches,_numberCaches);
	OO_SET(_category,AmmoCachesCategory,_ContainersPerCache,_containersPerCache);
	OO_SET(_category,AmmoCachesCategory,_ContainerTypes,_containerTypes);
};

OO_TRACE_DECL(SPM_AmmoCaches_Delete) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Root,Delete,MissionObjective);

	{
		if ((_x select 0) isEqualType objNull) then { deleteVehicle (_x select 0) };
		{ deleteVehicle _x } forEach (_x select 1);
	} forEach OO_GET(_category,AmmoCachesCategory,_Caches);
	OO_SET(_category,AmmoCachesCategory,_Caches,[]);
};

OO_TRACE_DECL(SPM_AmmoCaches_SetContainerDetectable) =
{
	params ["_category", "_container", "_detectable"];

	if (not _detectable) then
	{
		{ deleteVehicle _x } forEach (attachedObjects _container);
	}
	else
	{
		if (count attachedObjects _container == 0) then
		{
			private _charge = "DemoCharge_Remote_Ammo" createVehicle (call SPM_Util_RandomSpawnPosition);
			_charge attachTo [_container, [0,0,-0.2]];
			_charge allowDamage false;
		};
	};
};

private _defaultContainersPerCache = [1,4];

OO_BEGIN_SUBCLASS(AmmoCachesCategory,Category);
	OO_OVERRIDE_METHOD(AmmoCachesCategory,Root,Create,SPM_AmmoCaches_Create);
	OO_OVERRIDE_METHOD(AmmoCachesCategory,Root,Delete,SPM_AmmoCaches_Delete);
	OO_OVERRIDE_METHOD(AmmoCachesCategory,Category,Update,SPM_AmmoCaches_Update);
	OO_DEFINE_METHOD(AmmoCachesCategory,SetContainerDetectable,SPM_AmmoCaches_SetContainerDetectable);
	OO_DEFINE_PROPERTY(AmmoCachesCategory,ContainersDetectable,"BOOL",true);
	OO_DEFINE_PROPERTY(AmmoCachesCategory,_Garrison,"#OBJ",OO_NULL); // The garrison used to pick cache locations
	OO_DEFINE_PROPERTY(AmmoCachesCategory,_NumberCaches,"SCALAR",4);
	OO_DEFINE_PROPERTY(AmmoCachesCategory,_ContainersPerCache,"ARRAY",_defaultContainersPerCache); // [minimum, maximum]
	OO_DEFINE_PROPERTY(AmmoCachesCategory,_ContainerTypes,"ARRAY",[]); // [[container-type, damage, has-missiles], ...], or just container-type
	OO_DEFINE_PROPERTY(AmmoCachesCategory,_Caches,"ARRAY",[]); // [invisible-soldier, [container, container, ...]]
OO_END_SUBCLASS(AmmoCachesCategory);
