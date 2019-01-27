params ["_container"];

private _containerMass =
{
	params ["_container"];

	private _mass = 0;
	private _magazines = getMagazineCargo _container;
	{
		_mass = _mass + getNumber (configFile >> "CfgMagazines" >> _x >> "mass") * (_magazines select 1 select _forEachIndex);
	} forEach (_magazines select 0);

	private _weapons = getWeaponCargo _container;
	{
		_mass = _mass + getNumber (configFile >> "CfgWeapons" >> _x >> "WeaponSlotsInfo" >> "mass") * (_weapons select 1 select _forEachIndex);
	} forEach (_weapons select 0);

	private _items = getItemCargo _container;
	{
		_mass = _mass + getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "mass") * (_items select 1 select _forEachIndex);
	} forEach (_items select 0);

	_mass / 22;
};

private _mass = [_container] call _containerMass;
{
	_mass = _mass + ([_x select 1] call _containerMass);
} forEach everyContainer _container;

_mass
