private _unit = param [0, objNull, [objNull]];
private _scanForTargets = param [1, nil, [{}]];
private _scanInterval = param [2, 5, [0]];

[_unit, _scanForTargets, _scanInterval] spawn
{
	params ["_unit", "_scanForTargets", "_scanInterval"];

	scriptName "JB_fnc_restrictedTargeting";

	private _gunner = gunner _unit;

	private _currentTarget = objNull;

	while { alive _unit } do
	{
		// These three settings are here because I can't figure out when they can be executed during a mission startup.  They
		// have no effect if executed during a vehicle init.
		_unit setAutonomous true;
		_gunner disableAI "autotarget";
		_gunner disableAI "target";

		private _targets = [_unit] call _scanForTargets;

		if (not (_currentTarget in _targets) || { not alive _currentTarget }) then
		{
			_currentTarget = if (count _targets == 0) then { objNull } else { _targets select 0 };
			_unit doWatch objNull;

			if (not isNull _currentTarget) then
			{
				_unit doTarget _currentTarget;
				_unit doFire objNull;
			};
		};

		sleep _scanInterval;
	};
};
