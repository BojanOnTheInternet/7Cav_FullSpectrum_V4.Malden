private _state = param [0, "", [""]];

if (_state == "init") then
{
	[player, Repair_DefaultProfile] call JB_fnc_repairInit;

	[false] execVM "scripts\fatigueToggleInit.sqf";

	[] call MAP_InitializeGeneral;
	[] call HUD_Medic_Initialize;
	[] call HUD_Infantry_Initialize;

	player setVariable ["SPM_BranchOfService", "infantry"];

	[player] call CLIENT_SetInfantryVehiclePermissions;
	{
		player setVariable [_x, [[TypeFilter_MedicalVehicles, [], {}]] + (player getVariable _x)];
	} forEach ["VP_Driver"];

#define BRIEFING
#ifdef BRIEFING
	private _roleRecord = player createDiaryRecord ["diary", ["Medic",
		DOC_MedicDescription + "<br/>" +
		DOC_InfantryTransportAir + "<br/>" +
		DOC_InfantryTransportHALO + "<br/>" +
		DOC_Paradrop + "<br/>" +
		DOC_InfantryTransportBoat
	]];

	CLIENT_RoleLink = createDiaryLink ["Diary", _roleRecord, ""];
#endif
};

if (_state == "respawn") then
{
	player setUnitRecoilCoefficient 0.7;
	[0.4] call JB_fnc_weaponSwayInit;

	private _restrictions = [];
    _restrictions pushBack { [GR_All + GR_FinalPermissions] call GR_All};
    [_restrictions] call CLIENT_fnc_monitorGear;
};