params [["_vehicle", objNull, [objNull]]];

private _turretPath = [];
private _turretWeapons = [];
private _weaponType = "";

private _weapons = []; // [[turret-path, weapon-type, enabled], ...]
{
	_turretPath = _x select 0;
	_turretWeapons = _vehicle weaponsTurret _turretPath;
	{
		_weaponType = _x select 0;
		_weapons pushBack [_turretPath, _weaponType, _weaponType in _turretWeapons];
	} forEach (_x select 2);
} forEach (_vehicle getVariable ["JB_WC_Turrets", []]);

_weapons