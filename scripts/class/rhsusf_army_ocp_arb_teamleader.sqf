private _state = param [0, "", [""]];

if (_state == "init") then
{
	[] call MAP_InitializeGeneral;
	[] call HUD_Infantry_Initialize;

	player setVariable ["SPM_BranchOfService", "infantry"];

	[player] call CLIENT_SetSpecialOperationsVehiclePermissions;
};

if (_state == "respawn") then
{
	private _restrictions = [];
    _restrictions pushBack { [GR_All + GR_FinalPermissions] call GR_All};
    [_restrictions] call CLIENT_fnc_monitorGear;
};