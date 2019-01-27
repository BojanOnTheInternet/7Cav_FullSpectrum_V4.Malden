params ["_whitelistWeapons"];

private _addMagazines =
{
	params ["_magazines", "_additions"];

	_additions = _additions select { getText (configFile >> "CfgMagazines" >> _x >> "picture") != "" } apply { [_x, toLower getText (configFile >> "CfgMagazines" >> _x >> "displayName")] };

	private _filtered = _additions select { (_x select 1) find "green" == -1 && { (_x select 1) find "yellow" == -1 } };
	if (count _filtered == 0) then
	{
		_filtered = _additions select { (_x select 1) find "green" == -1 };
		if (count _filtered == 0) then { _filtered = _additions }
	};

	{
		_magazines pushBackUnique (_x select 0);
	} forEach _filtered;
};

private _magazines = [];
{
	private _weapon = _x;
	{
		if (_x == "this") then
		{
			[_magazines, getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines")] call _addMagazines;
		}
		else
		{
			[_magazines, getArray (configFile >> "CfgWeapons" >> _weapon >> _x >> "magazines")] call _addMagazines;
		};
	} forEach (getArray (configFile >> "CfgWeapons" >> _weapon >> "muzzles"));
} forEach _whitelistWeapons;

_magazines