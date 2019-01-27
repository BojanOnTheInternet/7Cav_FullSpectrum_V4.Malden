private _state = param [0, "", [""]];

if (_state == "init") then
{
	[player, Repair_ArmorProfile] call JB_fnc_repairInit;

	[false] execVM "scripts\fatigueToggleInit.sqf";

	[] call MAP_InitializeGeneral;
	[] call HUD_Armor_Initialize;

	player setVariable ["SPM_BranchOfService", "armor"];

	[player] call CLIENT_SetArmorCrewVehiclePermissions;

#define BRIEFING
#ifdef BRIEFING
	private _roleDescription =
"You are an armor crewman, able to operate heavy armored vehicles; M2A1 Slammers, FV-720 Moras, Rhino MGSs, the IFV-6a Cheetah, as well as captured enemy armor.  You may operate a vehicle
by yourself or in cooperation with up to two other crewmen.  You are responsible for patrolling main operations outside the infantry area (indicated by a red or blue ring on the map). When
you are mounted in your vehicle at an active operation, enemy armor units will be sent to engage you, and it is your job to disable or destroy them.  You are encouraged
to focus on armored vehicles and to leave the task of fighting enemy infantry to other players.  Enemy infantry will include both light and heavy RPG gunners, as well as grenadiers,
each of which is a threat to your vehicle.<br/><br/>
Solo operation of an armored vehicle is accomplished by entering as the gunner and selecting the scroll wheel option 'Manual drive'.  You can then use your driving controls and your
gunnery controls at the same time.  While on manual drive, player crewmen will be unable to enter the driver's position.  To open that position to a player, select the scroll wheel
option 'Cancel manual drive'.  Leaving the gunner's position for any reason will automatically cancel manual drive.<br/>";

	private _roleRecord = player createDiaryRecord ["diary", ["Armor crewman",
		_roleDescription + "<br/>" +
		DOC_ArmorTransport + "<br/>" +
		DOC_VehicleRepairs + "<br/>" +
		DOC_VehicleAmmunition + "<br/>" +
		DOC_VehicleFuel + "<br/>" +
		DOC_ArmorCapture + "<br/>"
	]];

	CLIENT_RoleLink = createDiaryLink ["Diary", _roleRecord, ""];
#endif
};

if (_state == "respawn") then
{
	player setUnitRecoilCoefficient 0.85;
	[0.7] call JB_fnc_weaponSwayInit;

	[TypeFilter_ArmoredVehicles] call JB_fnc_manualDriveInitPlayer;

	private _restrictions = [];
    _restrictions pushBack { [GR_All + GR_FinalPermissions] call GR_All};
    [_restrictions] call CLIENT_fnc_monitorGear;
};