/*

This is the trigger condition to be used with JB_fnc_ejectDeadBodies when setting up an action
for the player.

[vehicle] call JB_fnc_ejectDeadBodiesCondition;

	vehicle - the vehicle for which JB_fnc_ejectDeadBodies is being considered

*/

params ["_vehicle"];

if (isNil "Ejector") exitWith { false };

({ not alive _x } count crew _vehicle) > 0