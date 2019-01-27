private _group = param [0, grpNull, [grpNull]];
private _position = param [1, [], [[]]];
private _radius = param [2, 100, [0]];

[_group, _position, _radius] call SPM_PatrolRoads;