/*

Remove a vehicle from a trigger volume.  This function is designed to be called from a trigger's
OnActivation script.  See also JB_fnc_ejectVehicleFromTriggerAreaCondition.

If the vehicle has been initialized with JB_fnc_respawnVehicleInitialize the script will return the unit
to its original location.  If not set, the vehicle will be deleted.

[units, typeWhiteList, typeBlackList, unitWhiteList, unitBlackList] call JB_fnc_ejectVehicleFromTriggerAreaCondition;

	units - use the thisList variable in the trigger condition
	typeWhiteList - a list of unit types which are always permitted in the trigger area
	typeBlackList - a list of unit types which are never permitted in the trigger area
	unitWhiteList - a list of units which are always permitted in the trigger area
	unitBlackList - a list of units which are never permitted in the trigger area

	A unit which matches any white list is permitted.  A unit not mentioned by any list is permitted.

Examples:

[thisList, ["Man"], ["All"]] - ejects everything but men from the trigger area

Individual units may have the JBEV_DONOTEJECT variable set to true to indicate that they should not
be ejected from any trigger area.

*/

if (not isServer) exitWith {};

if (!canSuspend) then
{
	_this spawn JB_fnc_ejectVehicleFromTriggerArea;
}
else
{
	private _units = param [0, [], [[]]];
	private _typeWhiteList = param [1, [], [[]]];
	private _typeBlackList = param [2, [], [[]]];
	private _unitWhiteList = param [3, [], [[]]];
	private _unitBlackList = param [4, [], [[]]];

	private _doNotEject = false;

	{
		if (!([_x, _typeWhiteList, _typeBlackList, _unitWhiteList, _unitBlackList] call JB_fnc_unitWhiteListBlackList)) then
		{
			_doNotEject = _x getVariable ["JBEV_DONOTEJECT", false];

			if (!_doNotEject) then
			{
				[_x] call JB_fnc_respawnVehicleReturn;
			};
		};
	} foreach _units;
}