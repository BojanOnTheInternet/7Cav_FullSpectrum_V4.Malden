JBLS_GovernedVehicles = [];
JBLS_CS = call JB_fnc_criticalSectionCreate;

JBLS_RestrictVehicleSpeed =
{
	params ["_vehicle", "_targetSpeed"];

	private _targetSpeed = _targetSpeed * 0.2778; // km/h to m/s
	private _targetSpeedSqr = _targetSpeed * _targetSpeed;

	private _currentVelocity = velocityModelSpace _vehicle;
	private _currentSpeedSqr = vectorMagnitudeSqr _currentVelocity;

	if (_currentSpeedSqr > _targetSpeedSqr) then
	{
		private _currentSpeed = sqrt _currentSpeedSqr;
		if (_currentSpeed < 0.001) then
		{
			_vehicle setVelocityModelSpace [0, _targetSpeed, 0];
		}
		else
		{
			_vehicle setVelocityModelSpace (_currentVelocity vectorMultiply (_targetSpeed / _currentSpeed));
		};
	};
};

JBLS_Governor =
{
	private _i = 0;
	private _vehicle = objNull;

	while { true } do
	{
		JBLS_CS call JB_fnc_criticalSectionEnter;

		if (count JBLS_GovernedVehicles == 0) exitWith { JBLS_CS call JB_fnc_criticalSectionLeave };

		for "_i" from (count JBLS_GovernedVehicles - 1) to 0 step -1 do
		{
			_vehicle = JBLS_GovernedVehicles select _i;
			if (not alive _vehicle) then
			{
				JBLS_GovernedVehicles deleteAt _i;
			}
			else
			{
				_targetSpeed = _vehicle getVariable ["JBLS_GovernedSpeed", -1];
				if (_targetSpeed >= 0) then
				{
					[_vehicle, _targetSpeed] call JBLS_RestrictVehicleSpeed;
				};
			};
		};

		JBLS_CS call JB_fnc_criticalSectionLeave;

		sleep 0.2;
	};
};