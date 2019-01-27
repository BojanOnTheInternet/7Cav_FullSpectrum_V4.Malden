params ["_vehicle", "_magazineSubstitutions", "_weaponSubstitutions"];

private _magazineCargo = getMagazineCargo _vehicle;

private _magazineTypes = _magazineCargo select 0;
private _magazineCounts = _magazineCargo select 1;

clearMagazineCargoGlobal _vehicle;

{
	private _substitution = [_magazineSubstitutions, _x] call BIS_fnc_getFromPairs;

	if (isNil "_substitution") then
	{
		_vehicle addMagazineCargoGlobal [_x, _magazineCounts select _forEachIndex];
	}
	else
	{
		if (_substitution != "") then
		{
			_vehicle addMagazineCargoGlobal [_substitution, _magazineCounts select _forEachIndex];
		};
	};
} forEach _magazineTypes;

private _weaponCargo = getWeaponCargo _vehicle;

private _weaponTypes = _weaponCargo select 0;
private _weaponCounts = _weaponCargo select 1;

clearWeaponCargoGlobal _vehicle;

{
	private _substitution = [_weaponSubstitutions, _x] call BIS_fnc_getFromPairs;

	if (isNil "_substitution") then
	{
		_vehicle addWeaponCargoGlobal [_x, _weaponCounts select _forEachIndex];
	}
	else
	{
		if (_substitution != "") then
		{
			_vehicle addWeaponCargoGlobal [_substitution, _weaponCounts select _forEachIndex];
		};
	};
} forEach _weaponTypes;