private _state = param [0, "", [""]];

if (_state == "init") then
{
	
	[player, Repair_DefaultProfile] call JB_fnc_repairInit;

	[] call MAP_InitializeGeneral;
	[] call HUD_Pilot_Initialize;

	player setVariable ["SPM_BranchOfService", "air"];

	[player] call CLIENT_SetInfantryVehiclePermissions;
		
	switch (roleDescription player) do
	{
		case "Pilot (UH-60M)@BUFFALO-1":
		{
			{
				player setVariable [_x, [[TypeFilter_Buffalo, [], {}]] + (player getVariable _x)];
			} forEach ["VP_Pilot"];
		};
		case "Pilot (UH-60M)@BUFFALO-2":
		{
			{
				player setVariable [_x, [[TypeFilter_Buffalo, [], {}]] + (player getVariable _x)];
			} forEach ["VP_Pilot"];
		};
		case "Pilot (MH-6)@RAVEN-1":
		{
			{
				player setVariable [_x, [[TypeFilter_Raven, [], {}]] + (player getVariable _x)];
			} forEach ["VP_Pilot"];
		};
		case "Pilot (AH-6)@SPARROW-1":
		{
			{
				player setVariable [_x, [[TypeFilter_Sparrow, [], {}]] + (player getVariable _x)];
			} forEach ["VP_Pilot"];
		};
	};
	
	{
		player setVariable [_x, [[TypeFilter_BaseServiceVehicles, [], {}]] + (player getVariable _x)];
	} forEach ["VP_Driver"];

	// Override the infantry turret permissions so we can enable the copilot as appropriate
	_permissions = [];
	_permissions pushBack [TypeFilter_InfantryVehicles, [], {}];
    _permissions pushBack [TypeFilter_TransportAircraft, [], { if (player in [(_this select 0) turretUnit [0]]) then { (_this select 0) enableCopilot true } }];
	_permissions pushBack [TypeFilter_All, [VPC_UnlessTurretArmed, VPC_UnlessLogisticsDriving], {}];
	player setVariable ["VP_Turret", _permissions];
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