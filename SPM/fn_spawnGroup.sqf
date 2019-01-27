private _side = param [0, east, [west]];
private _descriptor = param [1, [], [[]]];
private _position = param [2, [], [[]]];
private _direction = param [3, 0, [0]];
private _loadInVehicles = param [4, true, [true]];
private _vehiclePositions = param [5, [], [[]]];

[_side, _descriptor, _position, _direction, _loadInVehicles, _vehiclePositions] call SPM_SpawnGroup;