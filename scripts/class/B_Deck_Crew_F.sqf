private _state = param [0, "", [""]];

if (_state == "init") then
{
	[false] execVM "scripts\fatigueToggleInit.sqf";

	[] call MAP_InitializeGeneral;
	[] call HUD_Infantry_Initialize;

	player setVariable ["SPM_BranchOfService", "infantry"];

#define BRIEFING
#ifdef BRIEFING
	private _roleDescription =
"Be sure to read both the Advances and Special Operations sections of the Briefing to understand the parameters and strategies of each.<br/><br/>
You are a recruiter.  You have no limitations on your access to vehicles and gear.<br/>";

	private _roleRecord = player createDiaryRecord ["diary", ["Recruiter",
		_roleDescription + "<br/>" +
		DOC_InfantryTransportAir + "<br/>" +
		DOC_InfantryTransportHALO + "<br/>" +
		DOC_Paradrop + "<br/>" +
		DOC_InfantryTransportBoat
	]];

	CLIENT_RoleLink = createDiaryLink ["Diary", _roleRecord, ""];
#endif

	player addHeadgear "H_Cap_oli";
};

if (_state == "respawn") then
{
	player allowDamage false;
};