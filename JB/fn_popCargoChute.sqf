/*
[vehicle, [["cargotype1", "chutetype", "lighttype", "smoketype"], ["cargotype2", "chutetype", "lighttype", "smoketype"]]]

chutetype, lighttype and smoketype are optional.  Default is cargo shute, no light and no smoke.  The light and smoke are actually just
a "thing that is attached on the way down" and a "thing that is attached when on the ground".  Air marker and ground marker or some such thing.

*/

JBPCC_GetDataForCargoType =
{
	params ["_cargoData", "_cargoType"];

	private _cargoDataForCargoType = [];

	{
		if (_cargoType isKindOf (_x select 0)) then
		{
			_cargoDataForCargoType = _x;
		}
	} foreach _cargoData;

	_cargoDataForCargoType;
};

JBPCC_FollowCargoToGround =
{
	params ["_cargo", "_smokeType", "_onLanded"];

	waitUntil { sleep 0.5; ((getPos _cargo) select 2) < 2 };

	detach _cargo;

	if (_smokeType != "") then
	{
		private _cargoBoundingBox = boundingBoxReal _cargo;
		private _cargoTop = (_cargoBoundingBox select 1) select 2;

		_smokeType createVehicle [(getPos _cargo) select 0, (getPos _cargo) select 1, ((getPos _cargo) select 2) + _cargoTop];
	};

	[_cargo] call _onLanded;
};

JBPCC_PopChute =
{
	private _vehicle = param [0, objNull, [objNull]];
	private _cargo = param [1, objNull, [objNull]];
	private _onLanded = param [2, {}, [{}]];

	if (isNull _cargo) exitWith {};

	private _cargoDataForCargo = [_vehicle getVariable ["JBPCC_CargoData", []], typeOf _cargo] call JBPCC_GetDataForCargoType;

	if (count _cargoDataForCargo > 0) then
	{
		private _chuteType = _cargoDataForCargo param [1, "B_Parachute_02_F", [""]];
		private _chuteHeight = _cargoDataForCargo param [2, 50, [0]];

		if ((getPos _cargo) select 2 > _chuteHeight) then
		{
			private _topOfCargoOffset = [0, 0, (((boundingBoxReal _cargo) select 1) select 2) + 0.3];

			[_vehicle, false] remoteExec ["allowDamage", _vehicle];
			[_cargo, false] remoteExec ["allowDamage", _cargo];

			private _chute = createVehicle [_chuteType, [-1000 - random 10000, -1000 - random 10000, 1000 + random 10000], [], 0, "CAN_COLLIDE"];
			_chute setDir (getDir _cargo);
			_chute setPos ((getPos _cargo) vectorAdd _topOfCargoOffset);

			_cargo attachTo [_chute, [0, 0, 0] vectorDiff _topOfCargoOffset];

			_chute say3D "CargoParachute"; // Sound listed in mission CfgSounds

			private _lightType = _cargoDataForCargo param [3, "", [""]];
			if (_lightType != "") then
			{
				_light = createVehicle [_lightType, position _chute, [], 0, 'NONE'];
				_light attachTo [_chute, [0, 0, 1]];
			};

			private _safeDistance = (sizeOf (typeOf _vehicle)) / 2 + (sizeOf (typeOf _cargo)) / 2;
			private _timer = diag_tickTime + 3;
			waitUntil { sleep 0.5; (_vehicle distance _chute) > _safeDistance || { diag_tickTime > _timer } };

			[_vehicle, true] remoteExec ["allowDamage", _vehicle];
			[_cargo, true] remoteExec ["allowDamage", _cargo];

			private _smokeType = _cargoDataForCargo param [4, "", [""]];

			[_cargo, _smokeType, _onLanded] spawn JBPCC_FollowCargoToGround;
		};
	};
};

_this spawn JBPCC_PopChute;