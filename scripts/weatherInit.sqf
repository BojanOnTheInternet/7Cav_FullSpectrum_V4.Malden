ZeusEnabledWeather = true;

[] spawn
{
	scriptName "WeatherInit";

	// SERVER_Weather = [[random-triple-for-overcast, chance-of-rain-per-storm-period, chance-of-storm-having-lightning], ...] one entry for each month

	if ((["Rain"] call JB_MP_GetParamValue) == 0) then
	{
		{
			_x set [1, 0];
		} forEach SERVER_Weather;
	};


	private _times = [date] call BIS_fnc_sunriseSunsetTime;
	private _nightEnd = (_times select 0) - 0.9;
	private _nightStart = (_times select 1) + 0.9;

	private _gameNightDuration = ((24 - _nightStart) + _nightEnd);
	private _realNightDuration = 2.0; // hours of realtime night
	private _acceleration = _gameNightDuration / _realNightDuration;

	private _month = date select 1;

	// 10 setfog [0.1,0.1,30]; // Morning coastal ground fog.  Have it start just before sunrise, then burn off an hour or two later (over 20 minutes or so)

	private _clientSetup =
	{
		//BUG: Force the appropriate clouds to be generated.  As of ARMA 1.80, generation of the initial clouds is unreliable
		waitUntil { not isNull player };

		private _overcast = overcast;
		private _fog = fog;

		0 setovercast 0;
		sleep 0.1;
		0 setovercast _overcast;
		0 setfog _fog;

		sleep 0.1;
		simulWeatherSync;
	};

	private _setOvercast =
	{
		params ["_overcast"];

		_overcast = (_overcast min 1) max 0;

		waitUntil { 0 setOvercast _overcast; sleep 0.1; forceWeatherChange; abs (overcast - _overcast) < 0.01 };
	};

	// Set the overcast level according to the month of the year
	private _values = (SERVER_Weather select (_month - 1) select 0);
	private _overcast = random _values;
	[_overcast] call _setOvercast;

	// Tell each client to force cloud display when starting a new session
	[[], _clientSetup] remoteExec ["spawn", 0, true]; //JIP

	private _time = 0;
	private _nextOvercastUpdate = 1e30;  //BUG: Disable overcast changes, which cause a momentary freeze on clients
	private _nextStormUpdate = 0;

	private _chanceOfRain = SERVER_Weather select (_month - 1) select 1;
	private _windDirection = random 360;
	private _rain = 0;
	private _fog = 0;
	private _lightning = 0;

	while { true } do
	{
		if (ZeusEnabledWeather) then {
			_time = diag_tickTime;

			(2 * random 5) setWindDir (_windDirection + (-60 + random 120));

			if (_fog == 0) then { 10 setFog 0 };

			if (_time >= _nextOvercastUpdate) then
			{
				_nextOvercastUpdate = _time + 60 * 60 + random (60 * 60);

				[random [(overcast - 0.25) max 0, overcast, (overcast + 0.25) min 1]] call _setOvercast;
			};

			if (_time >= _nextStormUpdate) then
			{
				private _stormDuration = 3 * 60 + random (12 * 60);
				_nextStormUpdate = _time + _stormDuration;

				private _transition = 1 + random 19;

				if (overcast > 0.5) then
				{
					_rain = 0;
					_fog = 0;
					_lightning = 0;

					if (random 1 < _chanceOfRain) then
					{
						_rain = random overcast;
						_fog = (_rain * 0.1);
						_lightning = random (SERVER_Weather select (_month - 1) select 2);
					};

					_transition setRain _rain;
					_transition setFog _fog;
					_transition setLightnings _lightning;
				};

				_transition setWindStr random overcast;
				_transition setWindForce overcast;
				_transition setGusts random overcast;
			};

			setTimeMultiplier (if (daytime > _nightStart || daytime < _nightEnd) then { _acceleration } else { 1.0 });

			sleep 10;
		} else {
			sleep 30;
		};

	};
};
