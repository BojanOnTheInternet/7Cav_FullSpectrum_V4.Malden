private _position = param [0, [], [[]]];
private _sizeX = param [1, 0, [0]];
private _sizeY = param [2, 0, [0]];
private _angle = param [3, 0, [0]];
private _number = param [4, 0, [0]];
private _types = param [5, ["ATMine_Range_Ammo", "APERSMine_Range_Ammo", "APERSBoundingMine_Range_Ammo"], [[]]];

[_position, _sizeX, _sizeY, _angle, _number, _types] call SPM_SpawnMineField