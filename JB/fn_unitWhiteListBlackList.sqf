/*

Determine if a unit passes a set of white and black lists.

[unit, typeWhiteList, typeBlackList, unitWhiteList, unitBlackList] call JB_fnc_unitWhiteListBlackList;

	unit - a list of units which should be checked
	typeWhiteList - a list of unit types which pass the check (default [])
	typeBlackList - a list of unit types which fail the check (default ["All"])
	unitWhiteList - a list of units which pass the check (default [])
	unitBlackList - a list of units which fail the check (default [])

	A unit not mentioned by any list passes the check

Examples:

[thisList, ["Man"], ["All"]] - return true for Man units and false for all others

*/

private _unit = param [0, objNull, [objNull]];
private _typeWhiteList = param [1, [], [[]]];
private _typeBlackList = param [2, ["All"], [[]]];
private _unitWhiteList = param [3, [], [[]]];
private _unitBlackList = param [4, [], [[]]];

private _passes = false;

{
	_passes = _passes || (_unit isKindOf _x);
} foreach _typeWhiteList;

if (!_passes) then
{
	{
		_passes = _passes || (_unit == _x);
	} foreach _unitWhiteList;
};

if (!_passes) then
{
	_passes = true;

	{
		_passes = _passes && !(_unit isKindOf _x);
	} foreach _typeBlackList;

	if (_passes) then
	{
		{
			_passes = _passes && !(_unit == _x);
		} foreach _unitBlackList;
	};
};

_passes;