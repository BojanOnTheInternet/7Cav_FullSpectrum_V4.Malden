diag_log "onPlayerRespawn start";

waitUntil { not isNull player };
waitUntil { not isNil "CLIENT_InitPlayerLocalComplete" };

private _respawn = player getVariable ["CLIENT_PlayerPosition", []];
player setPosASL (_respawn select 0);
player setDir (_respawn select 1);

[player] remoteExec ["SERVER_CuratePlayer", 2];

[player, [Headquarters, Carrier], []] execVM "scripts\greenZoneInit.sqf"; // No-combat zones

hideBody player;
[player, "novoice"] remoteExec ["setSpeaker", 0, true]; //JIP

if (not isNil "CLIENT_RespawnLoadout") then { player setUnitLoadout CLIENT_RespawnLoadout };

// Set camera view from the profile, and update the profile if the camera view changes
private _cameraView = profileNamespace getVariable "CLIENT_RespawnCamera";
if (not isNil "_cameraView" && { _cameraView in ["EXTERNAL", "INTERNAL"] }) then { player switchCamera _cameraView };
[] spawn
{
	scriptName "spawnOnPlayerRespawn-CameraView";

	private _player = player;
	private _cameraView = "";
	while { alive _player } do
	{
		sleep 10;
		_cameraView = profileNamespace getVariable ["CLIENT_RespawnCamera", "INTERNAL"];
		if (_cameraView != cameraView) then
		{
			profileNamespace setVariable ["CLIENT_RespawnCamera", cameraView];
			saveProfileNamespace;
		};
	};
};

CLIENT_ClearVehicleInventory =
{
	[] spawn
	{
		private _itemCount = 0; { _itemCount = _itemCount + _x } forEach ((getItemCargo vehicle player select 1) + (getWeaponCargo vehicle player select 1) + (getBackpackCargo vehicle player select 1) + (getMagazineCargo vehicle player select 1));
		private _message = format ["Clear inventory on %1? (%2 items)", [typeOf vehicle player] call JB_fnc_displayName, _itemCount];
		if ([_message, "CLEAR VEHICLE INVENTORY", true, true, findDisplay 46] call BIS_fnc_guiMessage) then { [vehicle player] call JB_fnc_containerClear };
	};
};

CLIENT_ClearVehicleInventoryCondition =
{
	if (vehicle player isKindOf "Man") exitWith { false };

	if (player != driver vehicle player && player != commander vehicle player && player != gunner vehicle player) exitWith { false };

	true
};

player addAction ["Clear vehicle inventory", CLIENT_ClearVehicleInventory, [], 0, false, true, "", "[] call CLIENT_ClearVehicleInventoryCondition"];
player addAction ["Unflip Vehicle", { [cursorTarget] call JB_fnc_flipVehicle }, [], 0, true, true, "", "(vehicle player) == player && { (player distance cursorTarget) < (sizeOf typeOf cursorTarget) * 0.3 } && { [cursorTarget] call JB_fnc_flipVehicleCondition }"];

["respawn"] call compile preProcessFile format ["scripts\class\%1.sqf", typeOf player];

diag_log "onPlayerRespawn end";