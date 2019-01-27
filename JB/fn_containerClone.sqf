params ["_container", "_sourceType"];

private _sourceConfig = (configFile >> "CfgVehicles" >> _sourceType);

clearItemCargoGlobal _container;
clearMagazineCargoGlobal _container;
clearWeaponCargoGlobal _container;
clearBackpackCargoGlobal _container;

{
	_entry = _x;
	{
		_count = getNumber (_x >> "count");
		_type = getText (_x >> (_entry select 1));

		[_container, _type, _count] call (_entry select 2);
	} forEach ("true" configClasses (_sourceConfig >> (_entry select 0)));
}
forEach [
			["TransportBackpacks", "backpack", { (_this select 0) addBackpackCargoGlobal [_this select 1, _this select 2] }],
			["TransportItems", "name", { (_this select 0) addItemCargoGlobal [_this select 1, _this select 2] }],
			["TransportMagazines", "magazine", { (_this select 0) addMagazineCargoGlobal [_this select 1, _this select 2] }],
			["TransportWeapons", "weapon", { (_this select 0) addWeaponCargoGlobal [_this select 1, _this select 2] }]
		];