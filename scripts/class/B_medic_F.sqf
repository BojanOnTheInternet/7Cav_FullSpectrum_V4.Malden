private _state = param [0, "", [""]];

if (_state == "init") then
{

	[] call MAP_InitializeGeneral;
	[] call HUD_Medic_Initialize;
	[] call HUD_Infantry_Initialize;

	player setVariable ["SPM_BranchOfService", "infantry"];

	[player] call CLIENT_SetInfantryVehiclePermissions;
	{
		player setVariable [_x, [[TypeFilter_MedicalVehicles, [], {}]] + (player getVariable _x)];
	} forEach ["VP_Driver"];
};

if (_state == "respawn") then
{
	private _restrictions = [];
    _restrictions pushBack { [GR_All + GR_FinalPermissions] call GR_All};
    [_restrictions] call CLIENT_fnc_monitorGear;
};