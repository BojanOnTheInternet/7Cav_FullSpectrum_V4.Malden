private _state = param [0, "", [""]];

if (_state == "init") then
{
	[player, Repair_DefaultProfile] call JB_fnc_repairInit;

	[] call MAP_InitializeGeneral;
	[] call HUD_SpecOps_Initialize;

	player setVariable ["SPM_BranchOfService", "special-forces"];

	[player] call CLIENT_SetSpecialOperationsVehiclePermissions;
	{
		player setVariable [_x, [[TypeFilter_ArmoredVehicles, [], {}]] + (player getVariable _x)];
	} forEach ["VP_Driver", "VP_Gunner", "VP_Commander", "VP_Turret"];
	private _kajman = [["Heli_Attack_02_base_F", true], ["All", false]];
	{
		player setVariable [_x, [[_kajman, [], { if (player in [(_this select 0) turretUnit [0]]) then { (_this select 0) enableCopilot false } }]] + (player getVariable _x)];
	} forEach ["VP_Turret"];

	[] execVM "scripts\disableThirdPerson.sqf";
};

if (_state == "respawn") then
{
	player setUnitRecoilCoefficient 0.5;
	[0.3] call JB_fnc_weaponSwayInit;
	player setStamina 120;

	private _restrictions = [];
    _restrictions pushBack { [GR_All + GR_FinalPermissions] call GR_All};
    [_restrictions] call CLIENT_fnc_monitorGear;
};