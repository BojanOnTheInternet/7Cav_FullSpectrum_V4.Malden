params ["_unit", "_magazineSubstitions", "_weaponSubstitutions"];

private _magazines = magazines _unit;
private _uniqueMagazines = []; { _uniqueMagazines pushBackUnique _x } forEach _magazines;

{
	private _magazine = _x;
	private _substitution = [_magazineSubstitions, _magazine] call BIS_fnc_getFromPairs;
	if (not isNil "_substitution") then
	{
		private _count = { _x == _magazine } count _magazines;
		_unit removeMagazines _magazine;
		for "_i" from 1 to _count do
		{
			_unit addMagazine _substitution;
		};
	};
} forEach _uniqueMagazines;

private _substitution = [_weaponSubstitutions, primaryWeapon _unit] call BIS_fnc_getFromPairs;
if (not isNil "_substitution") then
{
	_unit removeWeapon primaryWeapon _unit;
	if (_substitution != "") then { _unit addWeapon _substitution };
};

private _substitution = [_weaponSubstitutions, secondaryWeapon _unit] call BIS_fnc_getFromPairs;
if (not isNil "_substitution") then
{
	_unit removeWeapon secondaryWeapon _unit;
	if (_substitution != "") then { _unit addWeapon _substitution };
};

private _substitution = [_weaponSubstitutions, handgunWeapon _unit] call BIS_fnc_getFromPairs;
if (not isNil "_substitution") then
{
	_unit removeWeapon handgunWeapon _unit;
	if (_substitution != "") then { _unit addWeapon _substitution };
};