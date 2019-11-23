private _pump = param [0, objNull, [objNull]];
private _fuelCapacity = param [1, 10000, [0]];
private _fuelFlowRate = param [2, 4.5, [0]];

// Remove fuel from static pump everywhere
[_x, 0] remoteExec ["setFuelCargo", 0, true]; //JIP

// Hide the original, then create and initialize our proxy
hideObjectGlobal _pump;

private _replacement = createVehicle ["Land_fs_feed_f", getPosATL _pump, [], 0, "can_collide"];
_replacement setDir (getDir _pump);
_replacement setFuelCargo 0;
[_replacement, [[-0.396,0.035,-0.249], [0.396,0.035,-0.249]], _fuelCapacity, _fuelFlowRate] call JB_fnc_fuelInitSupply;