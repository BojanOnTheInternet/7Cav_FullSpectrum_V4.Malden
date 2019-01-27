private _group = _this select 0;
private _position = _this select 1;
private _radius = _this select 2;
private _visit = _this select 3;
private _enter = _this select 4;

[_group, _position, _radius, _visit, _enter] call SPM_PatrolBuildings;