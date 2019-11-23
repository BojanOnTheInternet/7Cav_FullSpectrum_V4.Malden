params [["_container", objNull, ["", objNull]]];

if (_container isEqualType "") exitWith { getNumber (configFile >> "CfgVehicles" >> _container >> "maximumLoad") > 0 };

if (not (_container isKindOf "GroundWeaponHolder")) exitWith { getNumber (configFile >> "CfgVehicles" >> typeOf _container >> "maximumLoad") > 0 };

count everyContainer _container > 0
