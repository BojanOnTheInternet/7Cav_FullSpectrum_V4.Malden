private _buildings = param [0, [], [[]]];
private _side = param [1, east, [sideUnknown]];

[_buildings, _side] call SPM_Occupy_GetBuildings;
