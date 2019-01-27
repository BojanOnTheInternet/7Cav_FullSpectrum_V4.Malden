private _state = param [0, "", [""]];

if (_state == "init") then
{
	[false] execVM "scripts\fatigueToggleInit.sqf";

	[] call MAP_InitializeGeneral;
	[] call HUD_Infantry_Initialize;

	player setVariable ["SPM_BranchOfService", "infantry"];

	player addHeadgear "H_Cap_oli";
	private _restrictions = [];
	
	_restrictions pushBack { [GR_RestrictedGear + GR_FinalPermissions] call GR_RestrictedGear};
	[_restrictions] call CLIENT_fnc_monitorGear;
};

if (_state == "respawn") then
{
	player allowDamage false;
	private _restrictions = [];
    _restrictions pushBack { [GR_All + GR_FinalPermissions] call GR_All};
    [_restrictions] call CLIENT_fnc_monitorGear;
};