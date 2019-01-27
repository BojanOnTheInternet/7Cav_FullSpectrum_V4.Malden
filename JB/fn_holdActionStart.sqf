params [["_keys", [], [[]]], ["_duration", 2, [0]], ["_interval", 0.25, [0]], ["_callback", {}, [{}]], "_passthrough"];

if (isNil "JB_HA_KeyUpHandler") then { JB_HA_KeyUpHandler = (findDisplay 46) displayAddEventHandler ["KeyUp", JB_HA_KeyUp] };
if (isNil "JB_HA_MouseButtonUpHandler") then { JB_HA_MouseButtonUpHandler = (findDisplay 46) displayAddEventHandler ["MouseButtonUp", JB_HA_MouseButtonUp] };
//if (count JB_HA_CurrentAction > 0) exitWith { false };

JB_HA_CurrentAction set [JB_HA_KEYS, _keys];
JB_HA_CurrentAction set [JB_HA_LABEL, ""];
JB_HA_CurrentAction set [JB_HA_DURATION, _duration];
JB_HA_CurrentAction set [JB_HA_INTERVAL, _interval];
JB_HA_CurrentAction set [JB_HA_CALLBACK, _callback];
JB_HA_CurrentAction set [JB_HA_PASSTHROUGH, _passthrough];
JB_HA_CurrentAction set [JB_HA_START_TIME, 0]; // Zero as flag
JB_HA_CurrentAction set [JB_HA_PROGRESS_STEP, -1];
JB_HA_CurrentAction set [JB_HA_INTERVAL_STEP, -1];
JB_HA_CurrentAction set [JB_HA_STATE, "active"];
JB_HA_CurrentAction set [JB_HA_FOREGROUND_ICON, nil];
JB_HA_CurrentAction set [JB_HA_FOREGROUND_ICON_SCALE, 1.7];
JB_HA_CurrentAction set [JB_HA_FOREGROUND_ICON_SETVALUE, nil];
JB_HA_CurrentAction set [JB_HA_FOREGROUND_ICON_SCALE_SETVALUE, nil];

[] spawn
{
	private _backgroundControl = findDisplay 46 ctrlCreate ["RscStructuredText", JB_HA_BACKGROUND_CONTROL_ID];
	(findDisplay 46 displayCtrl JB_HA_BACKGROUND_CONTROL_ID) ctrlSetPosition [0.25,0.55,0.5,0.5];
	(findDisplay 46 displayCtrl JB_HA_BACKGROUND_CONTROL_ID) ctrlCommit 0;
	private _foregroundControl = findDisplay 46 ctrlCreate ["RscStructuredText", JB_HA_FOREGROUND_CONTROL_ID];
	(findDisplay 46 displayCtrl JB_HA_FOREGROUND_CONTROL_ID) ctrlSetPosition [0.25,0.55,0.5,0.5];
	(findDisplay 46 displayCtrl JB_HA_FOREGROUND_CONTROL_ID) ctrlCommit 0;

	private _elapsedTime = 0.0;
	private _progress = 0.0;

	private _progressStep = 0.0;
	private _intervalStep = 0.0;
	private _key = "";

	while { count JB_HA_CurrentAction > 0 && { (JB_HA_CurrentAction select JB_HA_STATE) == "active" } } do
	{
		_startTime = JB_HA_CurrentAction select JB_HA_START_TIME;
		if (_startTime == 0) then { _startTime = diag_tickTime; JB_HA_CurrentAction set [JB_HA_START_TIME, _startTime] };

		_elapsedTime = diag_tickTime - _startTime;
		_progress = (_elapsedTime / (JB_HA_CurrentAction select JB_HA_DURATION)) min 1.0;

		_progressStep = floor (_progress * JB_HA_NUMBER_PROGRESS_STEPS);
		if (_progressStep != JB_HA_CurrentAction select JB_HA_PROGRESS_STEP) then
		{
			JB_HA_CurrentAction set [JB_HA_PROGRESS_STEP, _progressStep];
			_key = keyName ((JB_HA_CurrentAction select JB_HA_KEYS) select 0);
			_key = _key select [1, count _key - 2]; // Remove quotes
			(findDisplay 46 displayCtrl JB_HA_BACKGROUND_CONTROL_ID) ctrlSetStructuredText parseText ([_key, JB_HA_CurrentAction select JB_HA_LABEL, _progress] call JB_HA_GetBackgroundText);
		};

		private _icon = JB_HA_CurrentAction select JB_HA_FOREGROUND_ICON_SETVALUE;
		private _iconScale = JB_HA_CurrentAction select JB_HA_FOREGROUND_ICON_SCALE_SETVALUE;
		if (not isNil "_icon" || not isNil "_iconScale") then
		{
			if (isNil "_icon") then { _icon = JB_HA_CurrentAction select JB_HA_FOREGROUND_ICON };
			if (isNil "_iconScale") then { _iconScale = JB_HA_CurrentAction select JB_HA_FOREGROUND_ICON_SCALE };
			(findDisplay 46 displayCtrl JB_HA_FOREGROUND_CONTROL_ID) ctrlSetStructuredText parseText ([_icon, _iconScale] call JB_HA_GetForegroundText);
			JB_HA_CurrentAction set [JB_HA_FOREGROUND_ICON, _icon];
			JB_HA_CurrentAction set [JB_HA_FOREGROUND_ICON_SCALE, _iconScale];
			JB_HA_CurrentAction set [JB_HA_FOREGROUND_ICON_SETVALUE, nil];
			JB_HA_CurrentAction set [JB_HA_FOREGROUND_ICON_SCALE_SETVALUE, nil];
		};

		_intervalStep = floor (_elapsedTime / (JB_HA_CurrentAction select JB_HA_INTERVAL));
		if (_intervalStep != JB_HA_CurrentAction select JB_HA_INTERVAL_STEP) then
		{
			JB_HA_CurrentAction set [JB_HA_INTERVAL_STEP, _intervalStep];
			[_elapsedTime, _progress, JB_HA_CurrentAction select JB_HA_PASSTHROUGH] call (JB_HA_CurrentAction select JB_HA_CALLBACK);
		};

		sleep 0.1;
	};

	if (count JB_HA_CurrentAction > 0) then
	{
		if ((JB_HA_CurrentAction select JB_HA_STATE) == "keyup") then
		{
			[_elapsedTime, _progress, JB_HA_CurrentAction select JB_HA_PASSTHROUGH] call (JB_HA_CurrentAction select JB_HA_CALLBACK);
		};

		ctrlDelete (findDisplay 46 displayCtrl JB_HA_FOREGROUND_CONTROL_ID);
		ctrlDelete (findDisplay 46 displayCtrl JB_HA_BACKGROUND_CONTROL_ID);
		JB_HA_CurrentAction = [];
	};
};

true