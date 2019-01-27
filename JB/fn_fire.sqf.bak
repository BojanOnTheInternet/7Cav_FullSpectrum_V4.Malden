_this spawn
{
	params ["_parent", "_offset", "_duration", "_onCompletion", "_passthrough"];

	scriptName "spawnJB_fnc_fire";

	private _fire = createvehicle ["test_EmptyObjectForFireBig" , getPos _parent vectorAdd _offset, [], 0, "can_collide"];
	[{ isNull _parent }, _duration] call JB_fnc_timeoutWaitUntil;
	deleteVehicle _fire;
	if (not isNil "_onCompletion") then { [_passthrough] call _onCompletion };
};