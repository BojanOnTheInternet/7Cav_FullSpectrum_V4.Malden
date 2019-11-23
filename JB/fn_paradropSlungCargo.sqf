JBPSC_Paradrop =
{
	_this spawn
	{
		params ["_vehicle", "_cargo"];

		scriptName "JBPSC_Paradrop";

		private _attachChute = false;

		JBPSC_Lock call JB_fnc_criticalSectionEnter;

		if (not (_cargo getVariable ["JBPSC_Marked", false])) then
		{
			_cargo setVariable ["JBPSC_Marked", true];
			_attachChute = true;
		};

		JBPSC_Lock call JB_fnc_criticalSectionLeave;

		if (_attachChute) then
		{
			[_vehicle, _cargo, { (_this select 0) setVariable ["JBPSC_Marked", nil] } ] call JB_fnc_popCargoChute;
		};
	};
};

if (!isServer) exitWith {};

private _vehicle = param [0, objNull, [objNull]];
private _cargoTypes = param [1, [], [[]]];

if (count _cargoTypes > 0) then
{
	_vehicle setVariable ["JBPCC_CargoData", _cargoTypes];

	if (isNil "JBPSC_Lock") then { JBPSC_Lock = call JB_fnc_criticalSectionCreate  };

	_vehicle addEventHandler ["RopeBreak", { [(_this select 0), (_this select 2)] call JBPSC_Paradrop }];
};
