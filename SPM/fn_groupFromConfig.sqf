params ["_config"];

private _path = [_config] call BIS_fnc_configPath;
private _side =
	switch (toLower (_path select 2)) do
	{
		case "east": { east };
		case "west": { west };
		case "indep": { independent };
	};

private _descriptor = [];
{
	_descriptor pushBack [getText (_x >> "vehicle"), getText (_x >> "rank"), getArray (_x >> "position"), 0, nil];
} forEach ("true" configClasses _config);

[_side, _descriptor]