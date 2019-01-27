TROLLEY_RestrictToLogisticsArea =
{
	params ["_trolley"];

	if (not isServer) exitWith {};

	while { alive _trolley } do
	{
		if (not ([TRIGGER_Logistics, _trolley] call BIS_fnc_inTrigger)) then
		{
			private _player = attachedTo _trolley;
			if (isPlayer _player) then
			{
				[_player] remoteExec ["JBAT_ReleaseTrolley", owner _player];
			};
			[_trolley] call JB_fnc_respawnVehicleReturn;
		};

		sleep 3;
	};
};

[_this select 0] call JB_fnc_ammoInitTrolley;

[_this select 0] call JB_fnc_respawnVehicleInitialize;
[_this select 0] spawn TROLLEY_RestrictToLogisticsArea;