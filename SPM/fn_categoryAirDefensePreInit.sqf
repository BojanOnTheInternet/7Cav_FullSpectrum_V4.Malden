/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_AirDefense_Reload) =
{
	params ["_vehicle", "_weapon", "_magazineType", "_reloadDelay"];

	if (([magazinesAmmo _vehicle, _magazineType] call BIS_fnc_findInPairs) == -1) then
	{
		if (_weapon in (_vehicle weaponsTurret [0])) then
		{
			[_vehicle, _magazineType, _reloadDelay] spawn
			{
				params ["_vehicle", "_magazineType", "_reloadDelay"];

				scriptName "SPM_AirDefense_Reload";

				sleep _reloadDelay;

				if (alive _vehicle) then
				{
					if (_magazineType == "4Rnd_Titan_long_missiles_O") then
					{
						_vehicle removeMagazineTurret [_magazineType, [0]];
						_vehicle addMagazineTurret [_magazineType, [0], 1];
					}
					else
					{
						_vehicle removeMagazineTurret [_magazineType, [0]];
						_vehicle addMagazineTurret [_magazineType, [0]];
					};
				};
			};
		};
	};
};

OO_TRACE_DECL(SPM_AirDefense_IgnoreGround) =
{
	_this spawn
	{
		params ["_vehicle"];

		while { alive _vehicle } do
		{
			{
				switch (true) do
				{
					case (_x isKindOf "Man"):
					{
						if (not (_x isKindOf "B_crew_F") && { _x distance _vehicle > 100 } && { (weapons _x) findIf { [_x, SPM_Armor_AntiArmorWeapons] call JB_fnc_passesTypeFilter } == -1 }) then
						{
							_vehicle forgetTarget _x;
						};
					};

					case (_x isKindOf "Car"):
					{
						if (_x distance _vehicle > 100 && { not ([_x] call SPM_Util_HasOffensiveWeapons) }) then
						{
							_vehicle forgetTarget _x;
						};
					};
				};
			} forEach (effectiveCommander _vehicle targets [true]);

			sleep 1; // 1 second shuts down attacks.  2 seconds reduces them.  3 seconds produces no reduction.  forgetTarget may be intended for use in FSMs.
		};
	};
};


OO_TRACE_DECL(SPM_AirDefense_RequestSupport) =
{
	params ["_category", "_position"];

	private _supportPositions = OO_GET(_category,AirDefenseCategory,SupportPositions);

	private _matched = false;
	{
		if (_x distanceSqr _position < 300^2) exitWith { _matched = true };
	} forEach _supportPositions;

	if (not _matched) then { _supportPositions pushBack _position };
};

OO_TRACE_DECL(SPM_AirDefense_CreateUnit) =
{
	params ["_category", "_position", "_direction", "_type"];

	private _index = OO_GET(_category,ForceCategory,CallupsEast) findIf { _x select 0 == _type };
	if (_index == -1) exitWith {};
	private _vehicleDescriptor = OO_GET(_category,ForceCategory,CallupsEast) select _index select 1;

	private _unitVehicle = [_type, _position, _direction, ""] call SPM_fnc_spawnVehicle;
	_unitVehicle setVehicleTIPars [1.0, 0.5, 0.0]; // Start vehicle hot so it shows on thermals

	private _crew = [_unitVehicle] call SPM_fnc_groupFromVehicleCrew;
	private _crewSide = _crew select 0;
	private _crewDescriptor = _crew select 1;

	private _unitGroup = [_crewSide, [[_unitVehicle]] + _crewDescriptor, [_unitVehicle, 0.0] call SPM_PositionInFrontOfVehicle, 0, true] call SPM_fnc_spawnGroup;
	(driver _unitVehicle) setUnitTrait ["engineer", true];
	(driver _unitVehicle) addBackpack "B_LegStrapBag_black_repair_F";

	[_unitVehicle] call (_vehicleDescriptor select 3);
	[_category, _unitGroup] call OO_GET(_category,Category,InitializeObject);
	[_category, _unitVehicle] call OO_GET(_category,Category,InitializeObject);

	private _forceUnit = [_unitVehicle, units _unitGroup] call OO_CREATE(ForceUnit);

	OO_GET(_category,ForceCategory,ForceUnits) pushBack _forceUnit;
	private _forceRatings = [OO_GET(_forceUnit,ForceUnit,Units), OO_GET(_category,ForceCategory,CallupsEast)] call SPM_Force_GetForceRatings;

	if (count _forceRatings == 0) then
	{
		diag_log format ["SPM_AirDefense_CreateUnit: no force rating available for %1.  Created unit not charged against category reserves.", _type];
	}
	else
	{
		private _reserves = OO_GET(_category,ForceCategory,Reserves) - OO_GET(_forceRatings select 0,ForceRating,Rating);
		OO_SET(_category,ForceCategory,Reserves,_reserves);
	};

	_forceUnit
};

OO_TRACE_DECL(SPM_AirDefense_Retire) =
{
	params ["_forceUnitIndex", "_category"];

//	[_category, _forceUnitIndex] call SPM_Force_SalvageForceUnit;
};

OO_TRACE_DECL(SPM_AirDefense_Reinstate) =
{
	params ["_forceUnitIndex", "_category"];
};

OO_TRACE_DECL(SPM_AirDefense_CallUp) =
{
	params ["_position", "_direction", "_category", "_type"];

	if (OO_GET(_category,ForceCategory,_Surrendered)) exitWith {};

	private _forceUnit = [_category, _position, _direction, _type] call SPM_AirDefense_CreateUnit;

	sleep 5;

	if (not alive OO_GET(_forceUnit,ForceUnit,Vehicle)) exitWith
	{
		[_category, _forceUnit] call SPM_Force_SalvageForceUnit;
	};
};

OO_TRACE_DECL(SPM_AirDefense_Create) =
{
	params ["_category", "_area"];

	OO_SET(_category,ForceCategory,Area,_area);
};

OO_TRACE_DECL(SPM_AirDefense_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,ForceCategory);

	[OO_GET(_category,ForceCategory,ForceUnits), { not alive OO_GET(_x,ForceUnit,Vehicle) }] call SPM_Force_DeleteForceUnits;

	if (OO_GET(_category,ForceCategory,_Surrendered)) exitWith {};

	// If no possibility of callups or retirements, we're done
	private _supportPositions = OO_GET(_category,AirDefenseCategory,SupportPositions);
	if (count _supportPositions == 0 && count OO_GET(_category,ForceCategory,ForceUnits) == 0) exitWith {};

	private _westForce = [OO_GET(_category,ForceCategory,RangeWest)] call OO_METHOD(_category,ForceCategory,GetForceLevelsWest);
	private _eastForce = [2000] call OO_METHOD(_category,ForceCategory,GetForceLevelsEast);

	private _changes = [_category, _westForce, _eastForce] call SPM_Force_Rebalance;

	private _units = OO_GET(_category,ForceCategory,ForceUnits);

	{
		[[_units, { OO_GET(_this select 0,ForceUnit,Vehicle) == (_this select 1) }, _x] call SPM_Util_Find, _category] call SPM_AirDefense_Retire;
	} forEach CHANGES(_changes,retire);

	{
		[[_units, { OO_GET(_this select 0,ForceUnit,Vehicle) == (_this select 1) }, _x] call SPM_Util_Find, _category] call SPM_AirDefense_Reinstate;
	} forEach CHANGES(_changes,reinstate);

	private _callups = CHANGES(_changes,callup);
	if (count _callups > 0 && count _supportPositions > 0) then
	{
		private _supportIndex = 0;
		private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
		private _spawnManager = OO_GET(_strongpoint,Strongpoint,SpawnManager);

		{
			private _supportPosition = _supportPositions select _supportIndex;
			_supportIndex = (_supportIndex + 1) mod (count _supportPositions);

			private _positions = [_supportPosition, 30, 100, 10] call SPM_Util_SampleAreaGrid;
			[_positions, ["#GdtRoad", "#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
			[_positions, 5.0, ["WALL", "BUILDING", "HOUSE", "ROCK", "TREE"]] call SPM_Util_ExcludeSamplesByProximity;

			if (count _positions > 0) then
			{
				[selectRandom _positions, random 360, SPM_AirDefense_CallUp, [_category, _x select 0]] call OO_METHOD(_spawnManager,SpawnManager,ScheduleSpawn);
			};
		} forEach CHANGES(_changes,callup);
	};

	while { count _supportPositions > 0 } do
	{
		_supportPositions deleteAt 0;
	};
};

OO_BEGIN_SUBCLASS(AirDefenseCategory,ForceCategory);
	OO_OVERRIDE_METHOD(AirDefenseCategory,Root,Create,SPM_AirDefense_Create);
	OO_OVERRIDE_METHOD(AirDefenseCategory,Category,Update,SPM_AirDefense_Update);
	OO_DEFINE_METHOD(AirDefenseCategory,RequestSupport,SPM_AirDefense_RequestSupport);
	OO_DEFINE_PROPERTY(AirDefenseCategory,SupportPositions,"ARRAY",[]);
OO_END_SUBCLASS(AirDefenseCategory);
