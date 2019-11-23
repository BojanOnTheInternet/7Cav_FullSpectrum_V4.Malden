params [["_container", objNull, [objNull]], ["_condition", {true}, [{}]]];

if (not ([_container] call JB_fnc_containerIsContainer) || { [_container] call JB_fnc_containerIsLocked }) exitWith {};

[_container, _condition] call JB_CE_EditInventory;