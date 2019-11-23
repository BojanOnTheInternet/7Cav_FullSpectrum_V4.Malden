params [["_container", objNull, [objNull]]];

if (isNull _container) exitWith { true };

(count (getMagazineCargo _container select 0) == 0 && { count (getWeaponCargo _container select 0) == 0 } && { count (getItemCargo _container select 0) == 0 } && { count (getBackpackCargo _container select 0) == 0 })