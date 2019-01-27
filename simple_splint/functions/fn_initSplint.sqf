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

	[player] call simple_splint_fnc_addSplintOption
};
