JBR_VehicleComponents = [];

// getAllHitPointsDamage returns two arrays of names.  This list is keyed off the first name, but allows for the second name to be involved.  The entries with a funky addition
// on the end are taking advantage of names found in the second list that suggest that the first name isn't properly describing the component.
JBR_BaseComponents =
[
	["hitbody", ["Chassis", 20]],
	["hitcomgun", ["Commander's weapon", 4]],
	["hitcomturret", ["Commander's turret", 4]],
	["hitengine", ["Engine", 10]],
	["hitfuel", ["Fuel system", 6]],
	["hitgun", ["Gunner's weapon", 14], ["Commander's weapon", 4, "commander_gun_hit"]],
	["hithull", ["Chassis", 20]], // fuel_hitpoint
	["hitlbwheel", ["Wheel, left 4", 4]],
	["hitlf2wheel", ["Wheel, left 2", 4]],
	["hitlfwheel", ["Wheel, left 1", 4]],
	["hitlmwheel", ["Wheel, left 3", 4]],
	["hitltrack", ["Track, left", 20]],
	["hitrbwheel", ["Wheel, right 4", 4]],
	["hitrf2wheel", ["Wheel, right 2", 4]],
	["hitrfwheel", ["Wheel, right 1", 4]],
	["hitrmwheel", ["Wheel, right 3", 4]],
	["hitreservewheel", ["Wheel, spare", 4]],
	["hitrtrack", ["Track, right", 20]],
	["hitturret", ["Gunner's turret", 10], ["Commander's turret", 2, "commander_turret_hit"]],

	["hitavionics", ["Avionics", 20]],
	["hitmissiles", ["Weapons systems", 10]],
	["hitengine1", ["Engine 1", 20]],
	["hitengine2", ["Engine 4", 20]],
	["hitengine", ["Engine", 20]],
	["hithrotor", ["Rotor, Main", 10]],
	["hitvrotor", ["Rotor, Tail", 10], ["Rotor, Main", 10, "main_rotor_1_hit"]],
	["hitengine6", ["Engine 6", 20]],
	["hitwinch", ["Sling", 6]],
	["hittransmission", ["Transmission", 20]],
	["hithydraulics", ["Hydraulics", 20]],
	["hitgear", ["Gear", 6]],
	["hithstabilizerl1", ["Stabilizer, Horizontal", 20]],
	["hithstabilizerr1", ["Stabilizer, Horizontal", 20]],
	["hitvstabilizer1", ["Stabilizer, Vertical", 20]],
	["hittail", ["Airframe", 20]],
	["hitpitottube", ["Avionics", 2]],
	["hitstaticport", ["Avionics", 2]],
	["hitstarter1", ["Starter", 4]],
	["hitstarter2", ["Starter", 4]],
	["hitstarter6", ["Starter", 4]],
	["hithull", ["Airframe", 20]],
	["hitengine", ["Engine", 20]],
	["hitengine2", ["Engine 4", 20]],
	["hitlcrudder", ["Rudder", 4]],
	["hitrrudder", ["Rudder", 4]],
	["hitlaileron", ["Aileron", 4]],
	["hitraileron", ["Aileron", 4]],
	["hitlcelevator", ["Elevator", 4]],
	["hitrelevator", ["Elevator", 4]],
	["hitengine4", ["Engine 4", 20]],
	["hitrotorvirtual", ["Rotor, Main", 20]],

	["hitfuel2", ["Fuel system", 6]],
	["hitfuell", ["Fuel system", 6]],
	["hitfuelr", ["Fuel system", 6]]
];

JBR_GetVehicleComponents =
{
	params ["_vehicle"];

	private _type = typeOf _vehicle;
	private _componentsIndex = -1; { if (_x select 0 == _type) exitWith { _componentsIndex = _forEachIndex } } forEach JBR_VehicleComponents;

	if (_componentsIndex >= 0) exitWith { JBR_VehicleComponents select _componentsIndex select 1 };

	private _multiplier = ln (getMass _vehicle / 1000);
	private _hitPointsDamage = getAllHitPointsDamage _vehicle;

	private _components = [];

	private _name0 = "";
	private _name1 = "";
	private _descriptor = [];
	private _component = [];
	private _componentIndex = -1;
	private _alternates = [];

	{
		_name0 = toLower _x;
		_name1 = toLower (_hitPointsDamage select 1 select _forEachIndex);

		switch (true) do
		{
			case (_name0 find "glass" != -1 || _name1 find "glass" != -1): { _components pushBack ["Glass", 2] };
			case (_name0 find "light" != -1 || _name1 find "light" != -1 || _name0 find "svetlo" != -1): { _components pushBack ["Lights", 2] };
			case (_name0 find "hitslat_" == 0): { _components pushBack ["Cage armor", 1 * _multiplier] };
			case (_name0 find "hitera_" == 0): { _components pushBack ["Reactive armor", 2 * _multiplier] };
			default
			{
				_componentIndex = -1; { if (_x select 0 == _name0) exitWith { _componentIndex = _forEachIndex } } forEach JBR_BaseComponents;

				if (_componentIndex == -1) then
				{
					_components pushBack ["Other systems", 1 * _multiplier];
				}
				else
				{
					_descriptor = JBR_BaseComponents select _componentIndex;

					_component = +(_descriptor select 1);

					_alternates = _descriptor select [2, 100] select { _x select 2 == _name1 };
					if (count _alternates > 0) then { _component = _alternates select 0 select [0, 2] };

					_component set [1, (_component select 1) * _multiplier];
					_components pushBack _component;
				};
			};
		};
	} forEach (_hitPointsDamage select 0);

	JBR_VehicleComponents pushBack [typeOf _vehicle, _components];

	_components
};

//TODO: Critical section to avoid losing repairs from multiple clients

JBR_R_RepairSystemDamage =
{
	params ["_vehicle", "_componentIndex", "_repairPercent", "_damageLimit"];

	private _damagePercent = _vehicle getHitIndex _componentIndex;
	if (_damagePercent > _damageLimit) then
	{
		private _componentDamage = (_damagePercent - _repairPercent) max _damageLimit;
		_vehicle setHitIndex [_componentIndex, _componentDamage];

		// Update global damage value.  That sets all hit point values, so set them again from our saved copy
		private _hitPointsDamage = getAllHitPointsDamage _vehicle;
		private _weightedDamage = 0.0;

		private _components = [_vehicle] call JBR_GetVehicleComponents;

		private _weights = 0;
		{
			if (_x select 0 != "") then
			{
				_weights = _weights + (_x select 1);
				_weightedDamage = _weightedDamage + (_hitPointsDamage select 2 select _forEachIndex) * (_x select 1);
			};
		} forEach _components;

		_weightedDamage = _weightedDamage / _weights;

		_vehicle setDamage _weightedDamage;

		{
			_vehicle setHitIndex [_forEachIndex, _x];
		} forEach (_hitPointsDamage select 2);
	};
};