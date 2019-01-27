_this spawn
{
	params ["_vehicle"];

	private _group = [west, [[_vehicle], ["B_pilot_F", "private", [0,0,0], 0, { (_this select 0) hideObjectGlobal true }]], call SPM_Util_RandomSpawnPosition, 0, true, ["driver"]] call SPM_fnc_spawnGroup;
	sleep 2; // Time to go through start sequence, which includes closing canopy
	deleteVehicle ((units _group) select 0);
	deleteGroup _group;
	_vehicle engineOn false;
};