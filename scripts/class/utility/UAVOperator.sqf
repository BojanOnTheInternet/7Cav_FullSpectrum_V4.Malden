player addAction ["Reboot drone", { [cursorTarget] call QS_fnc_actionRebootDrone; cursorTarget setCaptive true }, [], 0, false, true, "", "[cursorTarget, player] call QS_fnc_conditionRebootDrone", 3];

[] spawn
{
	scriptName "spawnMonitorNewUAVTerminal";

	private _knownDarters = [];

	while { true } do
	{
		// Check the operator to see if he's picked up a new terminal so we can take out all the air defense turrets
		{
			if (_x isKindOf "B_SAM_System_01_F" || _x isKindOf "B_SAM_System_02_F" || _x isKindOf "B_AAA_System_01_F") then
			{
				player disableUAVConnectability [_x, true];
			};
		} forEach allUnitsUAV;

		// Update any new darters to have maximum skills and no fear
		{
			if (count crew _x > 0) then
			{
				_knownDarters pushBack _x;

				[[_x]] remoteExec ["SERVER_CurateEditableObjects", 2];

				{
					private _member = _x;
					{ _member setSkill [_x, 1.0] } forEach ((configProperties [configFile >> "CfgAiSkill"]) apply { configName _x });
				} forEach crew (_this select 0);
				group driver (_this select 0) allowFleeing 0.0;
			};
		} forEach (allUnitsUAV select { _x isKindOf "B_UAV_01_F" && { not (_x in _knownDarters) }});

		sleep 10;
	};
};