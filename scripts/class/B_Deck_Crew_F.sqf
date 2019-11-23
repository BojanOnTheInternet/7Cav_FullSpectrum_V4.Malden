private _state = param [0, "", [""]];

if (_state == "init") then
{
	[false] execVM "scripts\fatigueToggleInit.sqf";

	[] call MAP_InitializeGeneral;
	[] call HUD_Infantry_Initialize;

	player setVariable ["SPM_BranchOfService", "infantry"];
};

if (_state == "respawn") then
{
	
};