_this spawn
{
	private _unit = _this select 0;
	private _open = _this select 1;
	private _position = param [2, [], [[]]];
	private _direction = param [3, 0, [0]];

	scriptName "JB_fnc_halo";

	[_unit] call HALO_AddParachute;

	// Make sure that the _unit is out of the aircraft.
	if (vehicle _unit != _unit) then
	{
		unassignVehicle _unit;
		[_unit] allowGetIn false;
		[_unit] orderGetIn false;
		moveOut _unit;
		waitUntil { vehicle _unit == _unit };
	};

	if (count _position > 0) then
	{
		_unit setPos _position;
		_unit setDir _direction;
	};

	_unit switchmove "halofreefall_non";
	_unit action ["SwitchWeapon", _unit, _unit, -1];

	if (isPlayer _unit) then
	{
		[] call HALO_InstallPlayerReserveParachute;
	};

	if (_open) then
	{
		waitUntil { sleep 0.1; not alive _unit || animationState _unit == "halofreefall_non"};

		if (alive _unit) then
		{
			sleep 2;
			_unit action ["OpenParachute"];
		};
	};

	// Wait until very close to the ground, then force the _unit onto the ground.  If incapacitated in a chute,
	// the chute doesn't ever let the _unit reach the ground.  isTouchingGround never goes true and the chute
	// never goes away.  Note that the chute hover problem seems to keep the _unit at just under 0.75 meters.
	waitUntil { sleep 1; not alive _unit || (getPos _unit select 2) < 1 };
	_unit setPosATL ((getPosATL _unit) vectorAdd [0, 0, -((getPos _unit) select 2)]);

	if (isPlayer _unit) then
	{
		[] call HALO_UninstallPlayerReserveParachute;
	};

	// So long as the _unit's body is on the ground, restore the backpack
	if (alive _unit) then
	{
		[_unit] call HALO_RestoreBackpack;
	};
};
