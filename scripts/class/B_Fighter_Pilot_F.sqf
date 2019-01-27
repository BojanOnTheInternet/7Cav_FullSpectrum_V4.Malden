private _state = param [0, "", [""]];

if (_state == "init") then
{
	removeBackpack player; // Parachute not needed
	[] call MAP_InitializeGeneral;
	[] call HUD_Pilot_Initialize;

	player setVariable ["SPM_BranchOfService", "air"];

	[player] call CLIENT_SetInfantryVehiclePermissions;

};

if (_state == "respawn") then
{
	player setUnitRecoilCoefficient 1.0;
	[1.0] call JB_fnc_weaponSwayInit;
	player enableFatigue true;

	private _restrictions = [];
    _restrictions pushBack { [GR_All + GR_FinalPermissions] call GR_All};
    [_restrictions] call CLIENT_fnc_monitorGear;
};