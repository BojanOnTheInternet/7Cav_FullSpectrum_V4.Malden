private _state = param [0, "", [""]];

if (_state == "init") then
{

	[] call MAP_InitializeGeneral;
	[] call HUD_Infantry_Initialize;
	[] call HUD_Repair_Initialize;

	player setVariable ["SPM_BranchOfService", "support"];
	player setVariable ["JBA_LogisticsSpecialist", true, true]; //JIP

	[player] call CLIENT_SetInfantryVehiclePermissions;
	{
		player setVariable [_x, [[TypeFilter_LogisticsVehicles, [], {}], [TypeFilter_All, [VPC_UnlessOccupied], {}]] + (player getVariable _x)];
		player setVariable [_x, [[TypeFilter_BaseServiceVehicles, [], {}]] + (player getVariable _x)];
	} forEach ["VP_Driver"];
};

if (_state == "respawn") then
{
	private _restrictions = [];
    _restrictions pushBack { [GR_All + GR_FinalPermissions] call GR_All};
    [_restrictions] call CLIENT_fnc_monitorGear;
};
