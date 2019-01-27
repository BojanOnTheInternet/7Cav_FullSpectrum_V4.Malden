params ["_object"];

if (_object isEqualType objNull) exitWith
{
	private _bounds = boundingBoxReal _object;

	private _x = (_bounds select 1 select 0) - (_bounds select 0 select 0);
	private _y = (_bounds select 1 select 1) - (_bounds select 0 select 1);
	private _z = (_bounds select 1 select 2) - (_bounds select 0 select 2);

	_x * _y * _z
};

private _type = _object;

if (isNil "JB_OV_VolumeSamples") then { JB_OV_VolumeSamples = [] };

// If a type is supplied, create an instance that we can measure.
private _sampleIndex = JB_OV_VolumeSamples findIf { _x select 0 == _type };

if (_sampleIndex == -1) then
{
	_instance = createSimpleObject [_type, [-10000 + random 10000, -10000 + random 10000, random 10000]];
	_instance enableSimulationGlobal false;
	_instance hideObjectGlobal true;
	_sampleIndex = count JB_OV_VolumeSamples;
	JB_OV_VolumeSamples pushBack [_type, _instance];
};

[JB_OV_VolumeSamples select _sampleIndex select 1] call JB_fnc_objectVolume