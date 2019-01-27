params ["_target", "_caller"];

if (vehicle _caller != _caller) exitWith { false };

if (not unitIsUAV _target) exitWith { false };

if (isNull driver _target) exitWith { false };

true