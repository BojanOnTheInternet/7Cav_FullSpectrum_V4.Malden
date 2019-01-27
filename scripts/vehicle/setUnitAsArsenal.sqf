params ["_unit"];

_unit setVariable ["SupplyType", "arsenal", true];

["AmmoboxInit", [_unit, false]] call BIS_fnc_arsenal;

private _permittedGear = [] call compile preprocessFileLineNumbers "scripts\arsenalGear.sqf";

[_unit, _permittedGear select 0, true] call BIS_fnc_addVirtualWeaponCargo;
[_unit, _permittedGear select 1, true] call BIS_fnc_addVirtualBackpackCargo;
[_unit, (_permittedGear select 2) + (_permittedGear select 3), true] call BIS_fnc_addVirtualItemCargo;

private _permittedMagazines = [(_permittedGear select 0) + ["Put", "Throw"]] call compile preprocessFileLineNumbers "scripts\whitelistMagazines.sqf";

[_unit, _permittedMagazines, true] call BIS_fnc_addVirtualMagazineCargo;