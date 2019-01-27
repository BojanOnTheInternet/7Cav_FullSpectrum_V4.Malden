params ["_container", "_magazineSubstitutions", "_weaponSubstitutions"];

private _magazineCargo = getMagazineCargo _container;

private _magazineTypes = _magazineCargo select 0;
private _magazineCounts = _magazineCargo select 1;

clearMagazineCargoGlobal _container;

{
	private _substitution = [_magazineSubstitutions, _x] call BIS_fnc_getFromPairs;

	if (isNil "_substitution") then
	{
		_container addMagazineCargoGlobal [_x, _magazineCounts select _forEachIndex];
	}
	else
	{
		if (_substitution != "") then
		{
			_container addMagazineCargoGlobal [_substitution, _magazineCounts select _forEachIndex];
		};
	};
} forEach _magazineTypes;

private _weaponCargo = getWeaponCargo _container;

private _weaponTypes = _weaponCargo select 0;
private _weaponCounts = _weaponCargo select 1;

clearWeaponCargoGlobal _container;

{
	private _substitution = [_weaponSubstitutions, _x] call BIS_fnc_getFromPairs;

	if (isNil "_substitution") then
	{
		_container addWeaponCargoGlobal [_x, _weaponCounts select _forEachIndex];
	}
	else
	{
		if (_substitution != "") then
		{
			_container addWeaponCargoGlobal [_substitution, _weaponCounts select _forEachIndex];
		};
	};
} forEach _weaponTypes;