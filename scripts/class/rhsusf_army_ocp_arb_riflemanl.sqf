private _state = param [0, "", [""]];

if (_state == "init") then
{
	[player, Repair_DefaultProfile] call JB_fnc_repairInit;

	[false] execVM "scripts\fatigueToggleInit.sqf";

	[] call MAP_InitializeGeneral;
	[] call HUD_Infantry_Initialize;

	player setVariable ["SPM_BranchOfService", "infantry"];

	[player] call CLIENT_SetInfantryVehiclePermissions;

#define BRIEFING
#ifdef BRIEFING
	private _roleDescription =
"Be sure to read both the Advances and Special Operations sections of the Briefing to understand the parameters and strategies of each.<br/><br/>
You are a rifleman.  Your responsibility is to engage the enemy infantry.  Your marksmanship is among the best in your squad, but you have access to a
limited set of assault rifles.<br/>";

	private _roleRecord = player createDiaryRecord ["diary", ["Rifleman",
		_roleDescription + "<br/>" +
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
	player setUnitRecoilCoefficient 0.5;
	[0.3] call JB_fnc_weaponSwayInit;

	private _restrictions = [];
    _restrictions pushBack { [GR_All + GR_FinalPermissions] call GR_All};
    [_restrictions] call CLIENT_fnc_monitorGear;
};