private _state = param [0, "", [""]];

if (_state == "init") then
{
	[] call MAP_InitializeGeneral;
	[] call HUD_Pilot_Initialize;

	player setVariable ["SPM_BranchOfService", "air"];

	[player] call CLIENT_SetInfantryVehiclePermissions;


	switch (roleDescription player) do
	{
		case "Eagle-1 Pilot@EAGLE-1":
		{
			{
				player setVariable [_x, [[TypeFilter_GroundAttackAircraft, [], {}]] + (player getVariable _x)];
			} forEach ["VP_Pilot"];
		};
		case "Eagle-2 Pilot@EAGLE-2":
		{
			{
				player setVariable [_x, [[TypeFilter_GroundAttackAircraft, [], {}]] + (player getVariable _x)];
			} forEach ["VP_Pilot"];
		};
		case "Pilot (C-130J)@TITAN-1":
		{
			{
				player setVariable [_x, [[TypeFilter_TransportFixedWing, [], {}]] + (player getVariable _x)];
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
