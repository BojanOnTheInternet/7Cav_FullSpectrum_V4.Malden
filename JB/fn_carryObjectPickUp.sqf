params ["_object"];

if (not ([_object] call JB_CO_PickUpActionCondition)) exitWith { false };

[_object] call JB_CO_PickUpAction;

true