params ["_vehicle", "_targetSpeed"];

JBLS_CS call JB_fnc_criticalSectionEnter;

if (_targetSpeed < 0) then
{
	_vehicle setVariable ["JBLS_GovernedSpeed", nil];

	private _index = JBLS_GovernedVehicles find _vehicle;
	if (_index >= 0) then
	{
		JBLS_GovernedVehicles deleteAt _index;
	};
}
else
{
	_vehicle setVariable ["JBLS_GovernedSpeed", _targetSpeed];

	if (not (_vehicle in JBLS_GovernedVehicles)) then
	{
		JBLS_GovernedVehicles pushBack _vehicle;
		if (count JBLS_GovernedVehicles == 1) then
		{
			[] spawn JBLS_Governor;
		};
	};
};

JBLS_CS call JB_fnc_criticalSectionLeave;