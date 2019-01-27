//
// Many weapons classes share the same display name.  We want to ignore all the variants and
// just include the base model.  That base model is defined as the class with the shortest
// name.  So if there are five classes with the same display name, the shortest class name is
// the one that we use to represent the whole group.
//
// For example, arifle_ARC_ghex_F has three variants such as arifle_ARC_ghex_ACO_Pointer_Snds_F,
// yet they all have the display name of "Type 115 6.5 mm (Green Hex)".  When we show gear to
// the player, we only want the short class name, not the variants.
//
PGC_AddConfigName =
{
	params ["_configName", "_pairs", "_configSection"];

	private _displayName = getText (configFile >> _configSection >> _configName >> "displayName");
	private _pairIndex = [_pairs, _displayName] call BIS_fnc_findInPairs;
	if (_pairIndex == -1) then
	{
		_pairs pushBack [_displayName, _configName];
	}
	else
	{
		private _pair = _pairs select _pairIndex;
		if (count _configName < count (_pair select 1)) then
		{
			_pair set [1, _configName];
			_pairs set [_pairIndex, _pair];
		};
	};

	_pairs
};

private _gear = [] call compile preprocessFile "scripts\whitelistGear.sqf";

private _pairs = [];

_pairs = [];
{
	if (getNumber (configFile >> "CfgWeapons" >> _x >> "scope") >= 2) then
	{
		_pairs = [_x, _pairs, "CfgWeapons"] call PGC_addConfigName;
	};
} foreach (_gear select 0);
_pairs sort true;
_pairs = _pairs apply { _x select 1 };
_pairs = _pairs - ["launch_RPG32_F", "launch_RPG32_ghex_F", "launch_RPG7_F"]; // Weapons which are whitelisted for use, but not available through arsenal
_gear set [0, _pairs];

_pairs = [];
{
	if (getNumber (configFile >> "CfgVehicles" >> _x >> "scope") >= 2) then
	{
		_pairs = [_x, _pairs, "CfgVehicles"] call PGC_addConfigName;
	};
} foreach (_gear select 1);
_pairs sort true;
_pairs = _pairs apply { _x select 1 };
_gear set [1, _pairs];

_pairs = [];
{
	if (getNumber (configFile >> "CfgWeapons" >> _x >> "scope") >= 2) then
	{
		_pairs = [_x, _pairs, "CfgWeapons"] call PGC_addConfigName;
	};
} foreach (_gear select 2);
_pairs sort true;
_pairs = _pairs apply { _x select 1 };
_pairs = _pairs - ["C_UavTerminal", "I_UavTerminal", "O_UavTerminal"]; // Items which are whitelisted for use, but not available through arsenal
_gear set [2, _pairs];

(_gear select 3) sort true;

_gear