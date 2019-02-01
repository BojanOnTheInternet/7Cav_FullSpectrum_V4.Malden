private _state = param [0, "", [""]];

if (_state == "init") then
{

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
			} forEach ["VP_Pilot", "VP_Turret"];
		};
		case "Pilot (UH-60M)@BUFFALO-2":
		{
			{
				player setVariable [_x, [[TypeFilter_Buffalo, [], {}]] + (player getVariable _x)];
			} forEach ["VP_Pilot", "VP_Turret"];
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
};

if (_state == "respawn") then
{
	private _restrictions = [];
    _restrictions pushBack { [GR_All + GR_FinalPermissions] call GR_All};
    [_restrictions] call CLIENT_fnc_monitorGear;
};
