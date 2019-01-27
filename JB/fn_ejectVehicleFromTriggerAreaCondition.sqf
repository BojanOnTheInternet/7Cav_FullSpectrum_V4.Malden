/*

This is the trigger condition to be used with JB_fnc_ejectVehicleFromTriggerArea.  This function
should be called with the trigger's thisList from the trigger's Condition.  The trigger should be
Server Only.

[units, typeWhiteList, typeBlackList, unitWhiteList, unitBlackList] call JB_fnc_ejectVehicleFromTriggerAreaCondition;

	units - use the thisList variable in the trigger condition
	typeWhiteList - a list of unit types which are always permitted in the trigger area
	typeBlackList - a list of unit types which are never permitted in the trigger area
	unitWhiteList - a list of units which are always permitted in the trigger area
	unitBlackList - a list of units which are never permitted in the trigger area

	A unit which matches any white list is permitted.  A unit not mentioned by any list is permitted.

The condition on the trigger should be (at least)

this && [thisList] call JB_fnc_ejectVehicleFromTriggerAreaCondition;

Examples:

[thisList, ["Man"], ["All"]] - return false for Man units and true for all others

*/

if (not isServer) exitWith { false };

private _units = param [0, [], [[]]];

private _typeWhiteList = param [1, [], [[]]];
private _typeBlackList = param [2, [], [[]]];
private _unitWhiteList = param [3, [], [[]]];
private _unitBlackList = param [4, [], [[]]];

private _fireTrigger = false;
{
	if (not ([_x, _typeWhiteList, _typeBlackList, _unitWhiteList, _unitBlackList] call JB_fnc_unitWhiteListBlackList)) exitWith { _fireTrigger = true };
} foreach _units;

_fireTrigger;