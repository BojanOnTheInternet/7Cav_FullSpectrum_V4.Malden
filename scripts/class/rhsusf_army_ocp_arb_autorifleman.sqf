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
You are an autorifleman.  Your responsibility is to bring automatic weapons fire to bear on enemy infantry.  You have a choice of several automatic weapons,
chambering rounds between 5.56mm and 7.62mm.  The larger the caliber of ammunition, the greater the firepower, but the less control that you will have while
firing, particularly in full automatic.<br/>";

	private _roleRecord = player createDiaryRecord ["diary", ["Autorifleman",
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
	player setUnitRecoilCoefficient 0.7;
	[0.4] call JB_fnc_weaponSwayInit;

	private _restrictions = [];
    _restrictions pushBack { [GR_All + GR_FinalPermissions] call GR_All};
    [_restrictions] call CLIENT_fnc_monitorGear;
};