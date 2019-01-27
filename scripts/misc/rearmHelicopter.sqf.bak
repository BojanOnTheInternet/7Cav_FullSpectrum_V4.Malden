params ["_helicopter"];

if (not (_helicopter isKindOf "Helicopter") || { _helicopter isKindOf "ParachuteBase"}) exitWith { };

[_helicopter, [["repair", 60, 0.0], ["refuel", 60, 1.0], ["rearm", 60, magazinesAllTurrets _helicopter]]] call JB_fnc_serviceVehicle;