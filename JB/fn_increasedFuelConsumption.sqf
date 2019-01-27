#define POLL_INTERVAL 0.2

// Liters per second per RPM
JBIFC_FuelConsumptionRate =
{
	params ["_vehicle"];

	private _vehicleMass = getMass _vehicle;

	private _vehicleRadius = vectorMagnitude (boundingBoxReal _vehicle select 0);

	private _vehicleDensity = _vehicleMass / (4.18 * _vehicleRadius * _vehicleRadius * _vehicleRadius);

	private _fuelConsumption = _vehicleDensity * 1.5e-9; // A magic number

//	private _vehicleArmored = (getText (configFile >> "CfgVehicles" >> (typeOf vehicle player) >> "vehicleClass") == "Armored");
//	if (_vehicleArmored) then { _fuelConsumption = _fuelConsumption * 2 };

//	private _vehicleTracked = (getNumber (configFile >> "CfgVehicles" >> (typeOf vehicle player) >> "tracksSpeed") != 0);
//	if (_vehicleTracked) then { _fuelConsumption = _fuelConsumption * 2 };

	_fuelConsumption
};

JBIFC_Start =
{
	params ["_vehicle"];

	private _fuelConsumption = [_vehicle] call JBIFC_FuelConsumptionRate;

	private _rpm = 0;
	while { (vehicle player) == _vehicle } do
	{
		if (local _vehicle) then
		{
			_rpm = _vehicle getSoundController "rpm";
			_vehicle setFuel (fuel _vehicle) - _rpm * _fuelConsumption * POLL_INTERVAL;
		};

		sleep POLL_INTERVAL;
	};
};

player addEventHandler ["GetInMan", { [vehicle player] spawn JBIFC_Start }];