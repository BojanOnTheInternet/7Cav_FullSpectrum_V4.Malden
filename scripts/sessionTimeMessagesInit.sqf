[] spawn
{
	scriptName "sessionTimeMessages";

	waitUntil { time > 0 }; // Wait for the time system to get sorted out

	private _sessionEndTimes = [3.0, 15.0]; // Hours
	private _sessionWarningTimes = [30, 15, 10, 5, 4, 3, 2, 1]; // Minutes

	private _startHour = missionStart select 3;
	private _startMinute = missionStart select 4;

	private _endHour = (_sessionEndTimes select { _x > _startHour}) select 0;

	// Figure out how many seconds remain in the session
	private _remainingTime = (_endHour - _startHour) - (_startMinute / 60);
	_remainingTime = _remainingTime * 3600;

	// Tell ARMA how much of the mission is left
	estimatedTimeLeft _remainingTime;

	private _warnings = _sessionWarningTimes apply { [_remainingTime - (_x * 60), format ["SERVER RESTART in about %1 minute%2", _x, ["s", ""] select (_x == 1)]] };

	while { count _warnings > 0 } do
	{
		private _warning = _warnings deleteAt 0;
		private _timeToWarning = (_warning select 0) - time;

		if (_timeToWarning > 0) then
		{
			sleep _timeToWarning;
			[[_warning select 1, "plain down", 0.5]] remoteExec ["titleText", 0];
		};
	};
};