params ["_container", ["_source", "", ["", objNull]], "_whitelist"];

// Whitelist is of the format [weapons, backpacks, items, magazines]

//TODO: If the object only exists locally (doesn't have a netID?) , don't use the global version of the addcargo commands

clearItemCargoGlobal _container;
clearMagazineCargoGlobal _container;
clearWeaponCargoGlobal _container;
clearBackpackCargoGlobal _container;

if (_source isEqualType "") then
{
	private _sourceConfig = (configFile >> "CfgVehicles" >> _source);
	private _destinationConfig = (configFile >> "CfgVehicles" >> typeOf _container);
	private _maximumLoad = getNumber (_destinationConfig >> "maximumLoad");
	private _whitelistCheck = {};
	private _whitelistSubset = [];
	private _remainingLoad = _maximumLoad;
	private _mass = 0;

	{
		_entry = _x;

		if (not isNil "_whitelist" && { not isNil { _whitelist select (_entry select 3) } }) then { _whitelistSubset = _whitelist select (_entry select 3); _whitelistCheck = { _x in _whitelistSubset } } else { _whitelistCheck = { true } };

		{
			_count = getNumber (_x >> "count");
			_type = getText (_x >> (_entry select 1));

			if (call _whitelistCheck) then
			{
				_mass = _type call (_entry select 4);
				if (_mass > 0) then { _count = _count min floor (_remainingLoad / _mass) };
				_remainingLoad = _remainingLoad - (_mass * _count);

				[_container, _type, _count] call (_entry select 2);
			};
		} forEach ("true" configClasses (_sourceConfig >> (_entry select 0)));
	}
	forEach [
				["TransportWeapons", "weapon", { (_this select 0) addWeaponCargoGlobal [_this select 1, _this select 2] }, 0, { getNumber (configFile >> "CfgWeapons" >> _this >> "WeaponSlotsInfo" >> "mass") }],
				["TransportBackpacks", "backpack", { (_this select 0) addBackpackCargoGlobal [_this select 1, _this select 2] }, 1, { getNumber (configFile >> "CfgVehicles" >> _this >> "mass") }],
				["TransportItems", "name", { (_this select 0) addItemCargoGlobal [_this select 1, _this select 2] }, 2, { getNumber (configFile >> "CfgWeapons" >> _this >> "ItemInfo" >> "mass") }],
				["TransportMagazines", "magazine", { (_this select 0) addMagazineCargoGlobal [_this select 1, _this select 2] }, 3, { getNumber (configFile >> "CfgMagazines" >> _this >> "mass") }]
			];
}
else
{
	private _sourceConfig = (configFile >> "CfgVehicles" >> typeOf _source);
	private _destinationConfig = (configFile >> "CfgVehicles" >> typeOf _container);
	private _maximumLoad = getNumber (_destinationConfig >> "maximumLoad");
	private _cargo = [];
	private _whitelistCheck = {};
	private _whitelistSubset = [];
	private _remainingLoad = _maximumLoad;
	private _mass = 0;

	{
		_entry = _x;

		if (not isNil "_whitelist" && { not isNil { _whitelist select (_entry select 2) } }) then { _whitelistSubset = _whitelist select (_entry select 2); _whitelistCheck = { _x in _whitelistSubset } } else { _whitelistCheck = { true } };

		_cargo = _source call (_entry select 0);
		{
			_count = _cargo select 1 select _forEachIndex;
			_type = _x;

			if (call _whitelistCheck) then
			{
				_mass = _type call (_entry select 3);
				if (_mass > 0) then { _count = _count min floor (_remainingLoad / _mass) };
				_remainingLoad = _remainingLoad - (_mass * _count);

				[_container, _type, _count] call (_entry select 1);
			};
		} forEach (_cargo select 0);
	}
	forEach [
				[{ getWeaponCargo _this }, { (_this select 0) addWeaponCargoGlobal [_this select 1, _this select 2] }, 0, { getNumber (configFile >> "CfgWeapons" >> _this >> "mass") }],
				[{ getBackpackCargo _this }, { (_this select 0) addBackpackCargoGlobal [_this select 1, _this select 2] }, 1, { getNumber (configFile >> "CfgVehicles" >> _this >> "mass") }],
				[{ getItemCargo _this }, { (_this select 0) addItemCargoGlobal [_this select 1, _this select 2] }, 2, { getNumber (configFile >> "CfgWeapons" >> _this >> "ItemInfo" >> "mass") }],
				[{ getMagazineCargo _this }, { (_this select 0) addMagazineCargoGlobal [_this select 1, _this select 2] }, 3, { getNumber (configFile >> "CfgMagazines" >> _this >> "mass") }]
			];
};