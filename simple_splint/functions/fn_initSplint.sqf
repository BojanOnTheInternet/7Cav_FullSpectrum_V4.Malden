/*
Name: SimpleSplint
Author: Bojan

Called upon initialize, adds the ACE interact option to all
*/
if(!isMultiplayer) exitWith {};
[] spawn
{
	waitUntil {!isNull player && player == player};
	waitUntil{!isNil "BIS_fnc_init"};
	waitUntil {!(isNull (findDisplay 46))};

	["simple_splint_init_evh", { _this call simple_splint_fnc_addSplintOptionLocal }] call CBA_fnc_addEventHandler;
	["simple_splint_init_evh", [player]] call CBA_fnc_globalEventJIP;
};
