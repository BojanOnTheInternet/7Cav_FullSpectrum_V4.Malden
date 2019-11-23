/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_UnitProvider_Update) =
{
	params ["_provider"];

	[] call OO_METHOD_PARENT(_provider,Category,Update,Category);
};

OO_BEGIN_SUBCLASS(UnitProvider,Category);
	OO_OVERRIDE_METHOD(UnitProvider,Category,Update,SPM_UnitProvider_Update);
	OO_DEFINE_PROPERTY(UnitProvider,Unit,"OBJECT",nil);
	OO_DEFINE_PROPERTY(UnitProvider,UnitDescription,"STRING","");
OO_END_SUBCLASS(UnitProvider);

OO_TRACE_DECL(SPM_ProvideGarrisonUnit_MemberDescription) =
{
	params ["_appearanceType"];

	private _description = getText (configFile >> "CfgVehicles" >> _appearanceType >> "displayName");
	_description = [_description] call SPM_Util_CleanedRoleDescription;

	private _side = "";
	if (_appearanceType find "LOP_US_" == 0) then { _side = "Novorossiya "};
	if (_appearanceType find "LOP_PMC_" == 0) then { _side = "PMC "};
	if (_appearanceType find "I_C_" == 0) then { _side = "Syndikat "};
	if (_appearanceType find "LOP_IRAN" == 0) then { _side = "AAF "};
	if (_appearanceType find "rhsusf_" == 0) then { _side = "NATO "};
	// Don't call out 'civilian'

	"the " + _side + _description
};

OO_TRACE_DECL(SPM_ProvideGarrisonUnit_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,UnitProvider);

	private _garrison = OO_GET(_category,ProvideGarrisonUnit,Garrison);
	private _forceUnits = OO_GET(_garrison,ForceCategory,ForceUnits);

	if (count _forceUnits == 0) exitWith {};

	private _units = [];
	{
		switch (_x) do
		{
			case "any": { _units = _forceUnits apply { OO_GET(_x,ForceUnit,Vehicle) } };
			case "garrisoned": { _units = OO_GET(_garrison,InfantryGarrisonCategory,HousedUnits) };
			case "garrisoned-housed": { _units = OO_GET(_garrison,InfantryGarrisonCategory,HousedUnits) select { [_x] call SPM_Occupy_IsOccupyingUnit } };
			case "garrisoned-outdoor": { _units = OO_GET(_garrison,InfantryGarrisonCategory,HousedUnits) select { not ([_x] call SPM_Occupy_IsOccupyingUnit) } };
			case "duty": { _units = (_forceUnits apply { OO_GET(_x,ForceUnit,Vehicle) }) - OO_GET(_garrison,InfantryGarrisonCategory,HousedUnits) };
		};
		if (count _units > 0) exitWith {};
	} forEach OO_GET(_category,ProvideGarrisonUnit,UnitStates);

	private _unit = objNull;

	if (count _units > 0) then
	{
		private _garrisonIndex = OO_GET(_category,ProvideGarrisonUnit,GarrisonIndex);

		if (_garrisonIndex != -1) then
		{
			if (_garrisonIndex < count _units) then { _unit = _units select _garrisonIndex };
		}
		else
		{
			_units = _units select { alive _x }; // Don't hand out dead units
			_units = _units select { side _x == OO_GET(_garrison,ForceCategory,SideEast) }; // Don't hand out captives and such
			_units = _units select { isNil { _x getVariable "PGU_Data" } }; // Don't hand out the same unit twice

			_unit = selectRandom _units;
		};

		private _appearanceType = OO_GET(_category,ProvideGarrisonUnit,AppearanceType);
		if (_appearanceType != "") then
		{
			private _unitPosition = getPosATL _unit;
			private _unitDirection = getDir _unit;

			private _descriptor = [[_appearanceType]] call SPM_fnc_groupFromClasses;

			private _appearanceSide = OO_GET(_category,ProvideGarrisonUnit,AppearanceSide);
			if (_appearanceSide == sideUnknown) then { _appearanceSide = _descriptor select 0 };

			private _group = [_appearanceSide, _descriptor select 1, _unitPosition, _unitDirection, false] call SPM_fnc_spawnGroup;
			[_garrison, _group] call OO_GET(_category,Category,InitializeObject);

			private _replacement = leader _group;

			[[_unit, [_unit]] call OO_CREATE(ForceUnit), [_replacement, [_replacement]] call OO_CREATE(ForceUnit)] call OO_METHOD(_garrison,ForceCategory,ReplaceUnit);

			deleteVehicle _unit;
			_unit = _replacement;
		};

		_unit setVariable ["PGU_Data", _category];

		private _curatorTag = OO_GET(_category,ProvideGarrisonUnit,CuratorTag);
		if (_curatorTag != "") then
		{
			[_unit, "PGU", _curatorTag] call TRACE_SetObjectString;
		};

		_unit addEventHandler ["Killed",
			{
				params ["_unit", "_killer", "_instigator"];

				private _category = _unit getVariable "PGU_Data";
				private _unitDescription = OO_GET(_category,UnitProvider,UnitDescription);
				if (_unitDescription == "") then { _unitDescription = getText (configFile >> "CfgVehicles" >> typeOf _unit >> "displayName" )};

				private _name = if (not isNull _instigator) then { name _instigator } else { "A series of unfortunate events" };

				private _message = format ["%1 has killed %2", _name, _unitDescription];

				[_category, [_message], "event"] call OO_METHOD(_category,Category,SendNotification);
			}];
	};

	OO_SET(_category,UnitProvider,Unit,_unit);
	OO_SET(_category,Category,UpdateTime,1e30);
};

OO_TRACE_DECL(SPM_ProvideGarrisonUnit_Create) =
{
	params ["_category", "_garrison", "_unitStates", "_garrisonIndex", "_appearanceType", "_appearanceSide", "_unitDescription", "_curatorTag"];

	OO_SET(_category,ProvideGarrisonUnit,Garrison,_garrison);
	OO_SET(_category,Category,GetUpdateInterval,{1});

	if (not isNil "_unitStates") then
	{
		OO_SET(_category,ProvideGarrisonUnit,UnitStates,_unitStates);
	};

	if (not isNil "_garrisonIndex") then
	{
		OO_SET(_category,ProvideGarrisonUnit,GarrisonIndex,_garrisonIndex);
	};

	if (not isNil "_appearanceType") then
	{
		OO_SET(_category,ProvideGarrisonUnit,AppearanceType,_appearanceType);
		private _unitDescription = [_appearanceType] call SPM_ProvideGarrisonUnit_MemberDescription;
		OO_SET(_category,UnitProvider,UnitDescription,_unitDescription);
	};

	if (not isNil "_appearanceSide") then
	{
		OO_SET(_category,ProvideGarrisonUnit,AppearanceSide,_appearanceSide);
	};

	if (not isNil "_unitDescription") then
	{
		OO_SET(_category,UnitProvider,UnitDescription,_unitDescription);
	};

	if (not isNil "_curatorTag") then
	{
		OO_SET(_category,ProvideGarrisonUnit,CuratorTag,_curatorTag);
	};
};

OO_BEGIN_SUBCLASS(ProvideGarrisonUnit,UnitProvider);
	OO_OVERRIDE_METHOD(ProvideGarrisonUnit,Root,Create,SPM_ProvideGarrisonUnit_Create);
	OO_OVERRIDE_METHOD(ProvideGarrisonUnit,Category,Update,SPM_ProvideGarrisonUnit_Update);
	OO_DEFINE_PROPERTY(ProvideGarrisonUnit,Garrison,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(ProvideGarrisonUnit,GarrisonIndex,"SCALAR",-1);
	OO_DEFINE_PROPERTY(ProvideGarrisonUnit,UnitStates,"STRING",["any"]); // Priority order of units to consider.  Values are: any, garrisoned, garrisoned-housed, garrisoned-outdoor, duty
	OO_DEFINE_PROPERTY(ProvideGarrisonUnit,AppearanceType,"STRING","");
	OO_DEFINE_PROPERTY(ProvideGarrisonUnit,AppearanceSide,"SIDE",sideUnknown);
	OO_DEFINE_PROPERTY(ProvideGarrisonUnit,CuratorTag,"STRING","");
OO_END_SUBCLASS(ProvideGarrisonUnit);
