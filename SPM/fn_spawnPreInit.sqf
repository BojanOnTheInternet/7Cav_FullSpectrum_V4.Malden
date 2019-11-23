/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// How long an AI corpse remains
#define CORPSE_DELAY 180
// How close a player must be to a corpse to prevent its deletion
#define CORPSE_PLAYER_PROXIMITY 5
// The maximum number of corpses we're willing to leave on the ground
#define MAX_CORPSES 50

// How long an AI wreck remains
#define WRECK_DELAY 240
// The maximum number of wrecks burning at one time
#define MAX_BURNING_WRECKS 10

SPM_RecordDeath =
{
	params ["_body", "_killer", "_instigator"];

//	[_body, "novoice"] remoteExec ["setSpeaker", 0]; // Stop corpses from speaking

#ifdef DELETE_RED_ON_RED
	if (isNull _instigator || { side _body == side _instigator }) exitWith
	{
		if ((vehicle _body) isKindOf "ParachuteBase") then { deleteVehicle vehicle _body };
		deleteVehicle _body;
	};
#endif

	private _units = units group _body select { alive _x };
	if (count _units == 0) then
	{
		[group _body] call SPM_DeletePatrolWaypoints;
	}
	else
	{
		group _body selectLeader selectRandom _units;
	};

	if (isNil "SPM_Corpses") then
	{
		SPM_Corpses = [];
		SPM_CorpseCS = call JB_fnc_criticalSectionCreate;

		[] spawn
		{
			scriptName "SPM_RecordDeath";

			private _pendingBodies = [];
			private _pendingBody = objNull;
			private _sleepDuration = 0;

			while { true } do
			{
				private _currentTime = diag_tickTime;

				SPM_CorpseCS call JB_fnc_criticalSectionEnter;

					// Move expired bodies to the _pendingBodies list for deletion
					while { count SPM_Corpses > MAX_CORPSES || { count SPM_Corpses > 0 && (SPM_Corpses select 0) select 1 < _currentTime }} do
					{
						_pendingBodies pushBack ((SPM_Corpses deleteAt 0) select 0);
					};

					// Delete any bodies scheduled for cleanup unless a player is nearby
					for "_i" from count _pendingBodies - 1 to 0 step -1 do
					{
						_pendingBody = _pendingBodies select _i;
						if ({ _pendingBody distance _x < CORPSE_PLAYER_PROXIMITY && { not (_x isKindOf "HeadlessClient_F") } } count allPlayers == 0) then
						{
							deleteVehicle (_pendingBodies deleteAt _i);
						};
					};

					if (count _pendingBodies > 0) then
					{
						_sleepDuration = 10; // We're trying to get rid of bodies, but players are nearby.  Check again soon.
					}
					else
					{
						if (count SPM_Corpses == 0) then
						{
							_sleepDuration = CORPSE_DELAY;
						}
						else
						{
							_sleepDuration = (((SPM_Corpses select 0) select 1) - _currentTime);
						};
					};

				SPM_CorpseCS call JB_fnc_criticalSectionLeave;

				sleep _sleepDuration;
			};
		};
	};

	SPM_Corpses pushBack [_body, diag_tickTime + CORPSE_DELAY];
};

SPM_RecordDestruction =
{
	params ["_wreck"];

	// If destroyed within three seconds of spawning, delete the wreck immediately
	if (diag_tickTime - (_wreck getVariable ["SPM_SpawnTime", 0]) < 3.0) exitWith
	{
		deleteVehicle _wreck;
	};

	if (isNil "SPM_Wrecks") then
	{
		SPM_Wrecks = [];
		SPM_WreckCS = call JB_fnc_criticalSectionCreate;

		[] spawn
		{
			private _sleepDuration = 0;

			scriptName "SPM_RecordDestruction";
			while { true } do
			{
				private _currentTime = diag_tickTime;

				SPM_WreckCS call JB_fnc_criticalSectionEnter;

					while { count SPM_Wrecks > 0 && { (SPM_Wrecks select 0) select 1 < _currentTime }} do
					{
						deleteVehicle ((SPM_Wrecks deleteAt 0) select 0);
					};

					if (count SPM_Wrecks == 0) then
					{
						_sleepDuration = WRECK_DELAY;
					}
					else
					{
						_sleepDuration = (((SPM_Wrecks select 0) select 1) - _currentTime);
					};

				SPM_WreckCS call JB_fnc_criticalSectionLeave;

				sleep _sleepDuration;
			};
		};
	};

	_wreck forceFlagTexture "";
	[_wreck, 0.8, 1.0] call SPM_RemoveRandomAmmunition;

	SPM_WreckCS call JB_fnc_criticalSectionEnter;

		SPM_Wrecks pushBack [_wreck, diag_tickTime + WRECK_DELAY];

		private _destructionEffects = SPM_Wrecks apply { (_x select 0) nearObjects ["#destructioneffects", 3] };

	SPM_WreckCS call JB_fnc_criticalSectionLeave;

	private _numberFiresToPutOut = (({ count _x > 0 } count _destructionEffects) - MAX_BURNING_WRECKS) max 0;

	{
		if (_numberFiresToPutOut == 0) exitWith {};
		if (count _x > 0) then
		{
			deleteVehicle (_x select 0);
			_numberFiresToPutOut = _numberFiresToPutOut - 1;
		}
	} forEach _destructionEffects;
};

SPM_RemoveRandomAmmunition =
{
	params ["_vehicle", "_fractionMin", "_fractionMax"];

	if (not local _vehicle) exitWith { _this remoteExec ["SPM_RemoveRandomAmmunition", _vehicle] };

	if (_fractionMin < 0.0 || _fractionMax < 0.0 || _fractionMax > 1.0 || _fractionMin > 1.0 || _fractionMin > _fractionMax) exitWith {};

	private _magazines = magazinesAllTurrets _vehicle;

	private _turrets = [];
	{
		_turrets pushBackUnique (_x select 1);
	} forEach _magazines;

	{
		private _turret = _x;
		private _magazinesTurret = []; { _magazinesTurret pushBackUnique _x } forEach (_vehicle magazinesTurret _turret);
		{
			private _magazineType = _x;
			private _ammoCount = 0; { _ammoCount = _ammoCount + (_x select 2) } forEach (_magazines select { (_x select 0) == _magazineType && (_x select 1) isEqualTo _turret });
			[_vehicle, _turret, _magazineType, -round (_ammoCount * (_fractionMin + random (_fractionMax - _fractionMin)))] call JBA_AdjustTurretAmmo;
		} forEach _magazinesTurret;
	} forEach _turrets;
};

SPM_PositionBehindVehicle =
{
	params ["_vehicle", "_distance"];

	private _box = boundingBoxReal _vehicle;

	private _position = _vehicle modelToWorld [0, (_box select 0 select 1) - _distance, 0];

	_position
};

SPM_PositionInFrontOfVehicle =
{
	params ["_vehicle", "_distance"];

	private _box = boundingBoxReal _vehicle;

	private _position = _vehicle modelToWorld [0, (_box select 1 select 1) + _distance, 0];

	_position
};

SPM_MoveIntoVehicleDriver =
{
	params ["_unit", "_vehicle", "_vehiclePositions"];

	if (_vehicle isKindOf "StaticWeapon") exitWith { [] }; // Statics weapons claim to have drivers

	private _driver = [];

	if (count _vehiclePositions == 0 || { "driver" in _vehiclePositions }) then
	{
		private _drivers = (fullCrew [_vehicle, "driver", true]) select { isNull (_x select 0) };
		if (count _drivers > 0) then
		{
			_driver = selectRandom _drivers;
			_unit assignAsDriver _vehicle;
			_unit moveInDriver _vehicle;
		};
	};

	_driver
};

SPM_MoveIntoVehicleGunner =
{
	params ["_unit", "_vehicle", "_vehiclePositions"];

	private _gunner = [];

	if (count _vehiclePositions == 0 || { "gunner" in _vehiclePositions }) then
	{
		private _gunners = (fullCrew [_vehicle, "gunner", true]) select { isNull (_x select 0) };
		if (count _gunners > 0) then
		{
			_gunner = selectRandom _gunners;
			_unit assignAsGunner _vehicle;
			_unit moveInGunner _vehicle;
		};
	};

	_gunner
};

SPM_MoveIntoVehicleCommander =
{
	params ["_unit", "_vehicle", "_vehiclePositions"];

	private _commander = [];

	if (count _vehiclePositions == 0 || { "commander" in _vehiclePositions }) then
	{
		private _commanders = (fullCrew [_vehicle, "commander", true]) select { isNull (_x select 0) };
		if (count _commanders > 0) then
		{
			_commander = selectRandom _commanders;
			_unit assignAsCommander _vehicle;
			_unit moveInCommander _vehicle;
		};
	};

	_commander
};

// True turrets.  Excludes cargo seats where the character can shoot
SPM_MoveIntoVehicleTurret =
{
	params ["_unit", "_vehicle", "_vehiclePositions"];

	private _turret = [];

	if (count _vehiclePositions == 0 || { "turret" in _vehiclePositions }) then
	{
		private _turrets = (fullCrew [_vehicle, "Turret", true]) select { isNull (_x select 0) && not (_x select 4) };
		if (count _turrets > 0) then
		{
			_turret = selectRandom _turrets;
			_unit assignAsTurret [_vehicle, _turret select 3];
			_unit moveInTurret [_vehicle, _turret select 3];
		};
	};

	_turret
};

// Select seats where units can use personal weapons first, then standard passenger seats
SPM_MoveIntoVehicleCargo =
{
	params ["_unit", "_vehicle", "_vehiclePositions"];

	private _seat = [];

	if (count _vehiclePositions == 0 || { "cargo" in _vehiclePositions }) then
	{
		private _seats = (fullCrew [_vehicle, "Turret", true]) select { isNull (_x select 0) && (_x select 4) };
		if (count _seats > 0) then
		{
			_seat = selectRandom _seats;
			_unit assignAsCargoIndex [_vehicle, _seat select 2];
			_unit moveInCargo [_vehicle, _seat select 2];
		}
		else
		{
			private _seats = (fullCrew [_vehicle, "cargo", true]) select { isNull (_x select 0) };
			if (count _seats > 0) then
			{
				_seat = selectRandom _seats;
				_unit assignAsCargoIndex [_vehicle, _seat select 2];
				_unit moveInCargo [_vehicle, _seat select 2];
			};
		};
	};

	_seat
};

SPM_MoveIntoVehicle =
{
	params ["_unit", "_vehicle", "_vehiclePositions"];

	private _driver = [_unit, _vehicle, _vehiclePositions] call SPM_MoveIntoVehicleDriver;
	if (count _driver > 0) exitWith { _driver };

	private _gunner = [_unit, _vehicle, _vehiclePositions] call SPM_MoveIntoVehicleGunner;
	if (count _gunner > 0) exitWith { _gunner };

	private _commander = [_unit, _vehicle, _vehiclePositions] call SPM_MoveIntoVehicleCommander;
	if (count _commander > 0) exitWith { _commander };

	private _turret = [_unit, _vehicle, _vehiclePositions] call SPM_MoveIntoVehicleTurret;
	if (count _turret > 0) exitWith { _turret };

	private _cargo = [_unit, _vehicle, _vehiclePositions] call SPM_MoveIntoVehicleCargo;
	if (count _cargo > 0) exitWith { _cargo };
};

//BUG: ARMA 1.90.  A vehicle that isn't local will fail the moveIn commands.  The AI will have to move to the vehicle and then get in.  While the vehicle
// can be made local, any turrets cannot.  So if a vehicle is going to load a driver and a gunner, and the vehicle is made local, the driver gets in
// correctly while the gunner must mount the vehicle manually.  Sometimes the driver doesn't wait for the gunner.  So the entire crew is left to get in
// manually in hopes that they'll sort things out.

SPM_SpawnGroup =
{
	params ["_side", "_descriptor", "_position", "_direction", ["_loadInVehicles", true, [true]], ["_vehiclePositions", [], [[]]]];

	private _group = createGroup _side;

	private _vehicles = [];
	private _vehicle = objNull;

	{
		if ((_x select 0) isEqualType objNull) then
		{
			private _unit = _x select 0;

			if (_unit isKindOf "Man") then
			{
				_unit join _group;

				if (_loadInVehicles && not isNull _vehicle) then
				{
					[_unit, _vehicle, _vehiclePositions] call SPM_MoveIntoVehicle;
				};
			}
			else
			{
				_vehicle = _unit;
				_vehicles pushBack _vehicle;
				_group addVehicle _vehicle;
			};
		}
		else
		{
			_x params ["_type", ["_rank", "private", [""]], ["_unitPosition", [0,0,0], [[]]], ["_unitDirection", 0, [0]], ["_unitInitialize", {}, [{}]]];

			_unitPosition = ([_unitPosition, _direction] call SPM_Util_RotatePosition2D);

			if (_type isKindOf "Man") then
			{
				private _unit = _group createUnit [_type, _position vectorAdd _unitPosition, [], 0, "can_collide"];
				[_unit] join _group; //ARMA: Necessary if side _type != side _group.  As of ARMA v1.82
				_unit setRank _rank;
				_unit setDir (_direction + _unitDirection);
				[_unit] call _unitInitialize;

				if (_loadInVehicles && not isNull _vehicle) then
				{
					[_unit, _vehicle, _vehiclePositions] call SPM_MoveIntoVehicle;
				};
			}
			else
			{
				_vehicle = [_type, _position vectorAdd _unitPosition, _direction + _unitDirection, ""] call SPM_fnc_spawnVehicle;
				[_vehicle] call _unitInitialize;
				_vehicles pushBack _vehicle;
				_group addVehicle _vehicle;
			};

		}
	} forEach _descriptor;

	{
		_x addEventHandler ["Killed", SPM_RecordDeath];
	} forEach units _group;

	_group
};

SPM_SpawnVehicle =
{
	params ["_type", "_position", "_direction", "_special"];

	private _vehicle = createVehicle [_type, call SPM_Util_RandomSpawnPosition, [], 0, _special];
	_vehicle setDir _direction;
	[_vehicle, _position] call SPM_Util_SetPosition;

	if (_vehicle isKindOf "AllVehicles") then
	{
		_vehicle setVariable ["SPM_SpawnTime", diag_tickTime];
		_vehicle addEventHandler ["Killed", SPM_RecordDestruction];
	};

	_vehicle
};

SPM_SpawnMineField =
{
	params ["_position", "_sizeX", "_sizeY", "_angle", "_number", "_types"];

	private _sin = sin -_angle;
	private _cos = cos -_angle;

	private _mines = [];
	for "_i" from 1 to _number do
	{
		private _x = ((random 2.0) - 1.0) * _sizeX;
		private _y = ((random 2.0) - 1.0) * _sizeY;

		private _minePosition = [_x * _cos - _y * _sin, _y * _cos + _x * _sin, 0];

		private _type = _types select (floor random (count _types));
		_mines pushBack (_type createVehicle (_position vectorAdd _minePosition));
	};

	_mines
};
