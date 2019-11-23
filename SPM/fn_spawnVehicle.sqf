private _type = param [0, "", [""]];
private _position = param [1, call SPM_Util_RandomSpawnPosition, [[]]];
private _direction = param [2, 0, [0]];
private _special = param [3, "can_collide", [""]];

[_type, _position, _direction, _special] call SPM_SpawnVehicle;
