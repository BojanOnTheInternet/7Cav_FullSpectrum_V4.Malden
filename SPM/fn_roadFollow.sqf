private _road = _this select 0;
private _position = _this select 1;
private _direction = _this select 2;
private _distance = _this select 3;

[_road, _position, _direction, _distance] call SPM_RoadFollow;