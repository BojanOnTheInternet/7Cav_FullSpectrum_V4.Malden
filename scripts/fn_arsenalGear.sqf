if (not isNil "CLIENT_ArsenalGear") exitWith { CLIENT_ArsenalGear };

private _gear = +([] call CLIENT_fnc_whitelistGear);

private _weapons = (_gear select 0) select { getNumber (configFile >> "CfgWeapons" >> _x >> "scope") >= 2 && { getText (configFile >> "CfgWeapons" >> _x >> "baseWeapon") in ["", _x] } };
_weapons = _weapons apply { [getText (configFile >> "CfgWeapons" >> _x >> "displayName"), _x] };
_weapons sort true;
_weapons = _weapons apply { _x select 1 };
_weapons = _weapons - ["launch_RPG7_F"]; // Weapons which are whitelisted for use, but not available through arsenal
_gear set [0, _weapons];

private _backpacks = (_gear select 1) select { getNumber (configFile >> "CfgVehicles" >> _x >> "scope") >= 2 };
_backpacks = _backpacks apply { [getText (configFile >> "CfgVehicles" >> _x >> "displayName"), _x] };
_backpacks sort true;
_backpacks = _backpacks apply { _x select 1 };
_backpacks = _backpacks - []; // Backpacks which are whitelisted for use, but not available through arsenal
_gear set [1, _backpacks];

private _items = (_gear select 2) select { getNumber (configFile >> "CfgWeapons" >> _x >> "scope") >= 2 };
_items = _items apply { [getText (configFile >> "CfgWeapons" >> _x >> "displayName"), _x] };
_items sort true;
_items = _items apply { _x select 1 };
_items = _items - ["C_UavTerminal"]; // Items which are whitelisted for use, but not available through arsenal
_gear set [2, _items];

(_gear select 3) sort true;

CLIENT_ArsenalGear = _gear;

CLIENT_ArsenalGear