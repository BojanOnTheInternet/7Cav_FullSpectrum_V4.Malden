// Thanks to aliascartoons on armaholic for the example of his flare mod

JBFL_FlareShell =
{
	params ["_shell", "_shellType", "_elapsedTime"];

	if (not hasInterface) exitWith {};

	if (isNull _shell) exitWith {};

	private _startTime = diag_tickTime - _elapsedTime;

	private _timeToLive = getNumber (configFile >> "CfgAmmo" >> _shellType >> "timeToLive");
	private _lightColor = getArray (configFile >> "CfgAmmo" >> _shellType >> "lightColor");
	_lightColor = _lightColor select [0, 3];

	private _light = "#lightpoint" createVehicle (getpos _shell);
	_light attachTo [_shell, [0,0,0]];

	_light setLightUseFlare true;
	_light setLightFlareSize (_timeToLive * 0.4);
	_light setLightDayLight true;

	_light setLightFlareMaxDistance 2000;

	_light setLightAmbient _lightColor;
	_light setLightColor _lightColor;
	_light setLightAttenuation [_timeToLive * 10.0, 1, 100, 0, _timeToLive * 1.0, _timeToLive * 9.0];

	// Flickering and fade out

	private _remainingTime = 0;
	private _maxIntensity = 100;
	private _baseIntensity = 0;

	while { alive _shell } do
	{
		_remainingTime = _timeToLive - (diag_tickTime - _startTime);
		_baseIntensity = _maxIntensity * ((_remainingTime / (_timeToLive * 0.03)) min 1.0);
		_light setLightIntensity (_baseIntensity - random (_baseIntensity * 0.15));
		sleep (0.1 + random 0.1);
	};

	deleteVehicle _light;
};