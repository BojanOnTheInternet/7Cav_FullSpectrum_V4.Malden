params ["_unit"];

[_unit] call JB_fnc_containerLock; // No longer usable as a container //TODO: Policy should be the caller's responsibility, but I don't want to bug Dakota (this is called in mission.sqm)

_unit setVariable ["SupplyType", "arsenal", true];

["AmmoboxInit", [_unit, false]] call BIS_fnc_arsenal;

private _permittedGear = [] call CLIENT_fnc_arsenalGear;

[_unit, _permittedGear select 0, true] call BIS_fnc_addVirtualWeaponCargo;
[_unit, _permittedGear select 1, true] call BIS_fnc_addVirtualBackpackCargo;
[_unit, (_permittedGear select 2) + (_permittedGear select 3), true] call BIS_fnc_addVirtualItemCargo;

private _permittedMagazines = [(_permittedGear select 0) + ["Put", "Throw"]] call CLIENT_fnc_whitelistMagazines;

[_unit, _permittedMagazines, true] call BIS_fnc_addVirtualMagazineCargo;

[_unit, "Box_NATO_WpsSpecial_F", 600, 120] call JB_fnc_containerProviderInitializeSource;
[_unit, -1, [["Box_NATO_WpsSpecial_F", true], ["All", false]]] call JB_fnc_internalStorageInitContainer; // Black hole for the weapon boxes
