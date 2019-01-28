private _state = param [0, "", [""]];

if (_state == "init") then
{
	[] call MAP_InitializeGeneral;
	[] call HUD_Pilot_Initialize;

	player setVariable ["SPM_BranchOfService", "air"];

	[player] call CLIENT_SetInfantryVehiclePermissions;

};

if (_state == "respawn") then
{
	private _restrictions = [];
    _restrictions pushBack { [GR_All + GR_FinalPermissions] call GR_All};
    [_restrictions] call CLIENT_fnc_monitorGear;
};