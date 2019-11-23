params [["_vehicle", objNull, [objNull]], ["_condition", nil, [{}]], ["_controlDefensiveWeapons", true, [true]]];

if (isNull _vehicle) exitWith { diag_log "WARNING: JB_fnc_weaponControlInitializeVehicle called with a null vehicle" };

[_vehicle, if (isNil "_condition") then { nil } else { _condition }, _controlDefensiveWeapons] call JB_WC_InitializeVehicle
