// "JBF_FuelSupply" provides the details of a vehicle that can supply fuel
// "JBF_FuelLine" [fuel-line-index, connected-object] identifies fuel line ropes on supplier objects (versus other uses of ropes)
// "JBF_FuelHandle" identifies an attached object as a fuel handle, including which rope it is attached to

// Length of a fuel line (m)
#define FUEL_LINE_LENGTH 15
// Distance at which a fuel line will automatically release and retract
#define FUEL_LINE_RETRACT_DISTANCE 11
// Rate at which a fuel line is retracted (m/s)
#define FUEL_LINE_RETRACT_RATE 3
// Time between refuel pulses (s)
#define FUEL_UPDATE_INTERVAL 1
// Distance from the player's location to the fuel port. (m)  Player's location is at his feet...
#define DISTANCE_FROM_FUEL_PORT_SQR 8
// Distance from the player's location to the fuel line origin (m)
#define DISTANCE_FROM_FUEL_LINE_SQR 8

// Must be capable of hosting ropes (ropeCreate)
#define ROPE_HOST_PROXY_CLASS "O_Static_Designator_02_F"

// Assume four standard fuel connection types and set fuel flow rates for each
#define ARMOR_REFUEL_RATE 60
#define AIR_REFUEL_RATE 50
#define BOAT_REFUEL_RATE 4.5
#define CAR_REFUEL_RATE 4.5

// array of [type, [gas-caps, flow-rate, fuel-capacity]]
// gas-caps = [[location, direction], ...]
JBF_FuelConsumers =
	[
		["Kart_01_Base_F",
			[[[[-0.062,0.372,-0.794], [-1,0,0]]], CAR_REFUEL_RATE, 4.0]],

		["Truck_01_Base_F",
			[[[[-1.021,0.562,-0.509], [0,0,1]]], CAR_REFUEL_RATE, 227.0]],

		["Van_02_base_F",
			[[[[-1.046,-0.322,-0.568], [-1,0,0]]], CAR_REFUEL_RATE, 80.0]],

		["LT_01_base_F",
			[[[[-1.156,-1.932,-0.835], [-1,0,0]]], CAR_REFUEL_RATE, 225.0]],

		["LSV_01_base_F", 
			[[[[-1.020,-1.087,-0.760], [-1,0,0]]], CAR_REFUEL_RATE, 95.0]],

		["LSV_02_base_F", 
			[[
				[[-1.167,-1.238,-0.374], [-1,0,0]],
				[[0.839,-1.238,-0.374], [1,0,0]]
			 ], CAR_REFUEL_RATE, 120.0]],

		["Offroad_01_base_F", 
			[[[[-1.030,-0.388,-0.827], [-1,0,0]]], CAR_REFUEL_RATE, 60.0]],

		["Offroad_02_base_F", 
			[[[[-0.890,-1.384,-0.418], [-1,0,0]]], CAR_REFUEL_RATE, 60.0]],

		["MRAP_01_base_F", 
			[[[[1.009,-2.650,-1.242], [1,0,0]]], CAR_REFUEL_RATE, 95.0]],

		["MRAP_03_base_F", 
			[[[[-1.035,-2.152,-0.401], [0,0,1]]], CAR_REFUEL_RATE, 95.0]],

		["MBT_01_base_F",
			[[
				[[1.564,-3.746,-0.6], [0,0,1]],
				[[-1.564,-3.746,-0.6], [0,0,1]]
			 ], ARMOR_REFUEL_RATE, 1900.0]],

		["MBT_02_base_F",
			[[
				[[-0.809,-4.357,-0.767], [0,0,1]],
				[[0.809,-4.357,-0.767], [0,0,1]]
			 ], ARMOR_REFUEL_RATE, 1900.0]],

		["MBT_03_base_F",
			[[
				[[-0.093,-5.242,-0.657], [0,0,1]],
				[[0.093,-5.242,-0.657], [0,0,1]]
			 ], ARMOR_REFUEL_RATE, 1900.0]],

		["APC_Wheeled_01_base_F",
			[[
				[[1.085,-4.593,-0.135], [0,0,1]],
				[[-1.085,-4.593,-0.135], [0,0,1]]
			 ], ARMOR_REFUEL_RATE, 300.0]],

		["APC_Wheeled_03_base_F",
			[[[[-0.433,-4.3,-0.337], [0,0,1]]], ARMOR_REFUEL_RATE, 300.0]],

		["APC_Tracked_01_base_F",
			[[[[-0.681,-4.519,-0.178], [0,0,1]]], ARMOR_REFUEL_RATE, 460.0]],

		["APC_Tracked_02_base_F",
			[[
				[[0.984,-4.275,-0.301], [0,0,1]],
				[[-0.984,-4.275,-0.301], [0,0,1]]
			 ], ARMOR_REFUEL_RATE, 460.0]],

		["AFV_Wheeled_01_base_F",
			[[
				[[1.290,-3.463,-0.330], [1,0,0]],
				[[-1.290,-3.463,-0.330], [-1,0,0]]
			 ], ARMOR_REFUEL_RATE, 300.0]],

		["Heli_Transport_01_base_F", 
			[[
				[[1.080,-0.881,-0.892], [1,0,0]],
				[[-1.080,-0.881,-0.892], [-1,0,0]]
			 ], AIR_REFUEL_RATE, 1360.0]],

		["Heli_Transport_03_base_F", 
			[[
				[[1.731,1.359,-1.268], [1,0,0]],
				[[-1.731,1.359,-1.268], [-1,0,0]],
				[[1.790,-1.199,-1.291], [1,0,0]],
				[[-1.790,-1.199,-1.291], [-1,0,0]]
			 ], AIR_REFUEL_RATE, 4000.0]],

		["Heli_Transport_04_Base_F", 
			[[
				[[3.705,-0.895,-0.966], [0,0,-1]],
				[[-3.705,-0.895,-0.966], [0,0,-1]]
			 ], AIR_REFUEL_RATE, 1360.0]],

		["Heli_Light_01_base_F", 
			[[
				[[0.443,-0.610,0.244], [1,0,0]],
				[[-0.443,-0.610,0.244], [-1,0,0]]
			 ], CAR_REFUEL_RATE, 242.0]],  // 1.78 km/l

		["Heli_Light_02_base_F", 
			[[
				[[0.866,-0.855,-0.594], [1,0,0]],
				[[-0.866,-0.855,-0.594], [-1,0,0]]
			 ], AIR_REFUEL_RATE, 1450.0]],

		["Heli_light_03_base_F", 
			[[
				[[0.826,0.143,0.570], [1,0,0]],
				[[-0.826,0.143,0.570], [-1,0,0]]
			 ], CAR_REFUEL_RATE, 835.0]],

		["Heli_Attack_01_base_F", 
			[[
				[[1.017,0.215,-0.312], [1,0,0]],
				[[-1.017,0.215,-0.312], [-1,0,0]]
			 ], AIR_REFUEL_RATE, 1420.0]],

		["Heli_Attack_02_base_F", 
			[[
				[[0.772,-2.236,-1.419], [1,0,0]],
				[[-0.772,-2.236,-1.419], [-1,0,0]]
			 ], AIR_REFUEL_RATE, 1450.0]],

		["VTOL_01_base_F", 
			[[
				[[2.547,3.818,-4.120], [1,0,0]],
				[[-2.547,3.818,-4.120], [-1,0,0]]
			 ], AIR_REFUEL_RATE, 5000.0]],

		["VTOL_02_base_F", 
			[[
				[[-1.314,2.599,-1.735], [-1,0,0]],
				[[1.314,2.599,-1.735], [1,0,0]]
			 ], AIR_REFUEL_RATE, 5000.0]],

		["Plane_CAS_01_base_F", 
			[[[[0.25,-1.677,-0.591], [0,0,-1]]], AIR_REFUEL_RATE, 6000.0]],

		["Plane_CAS_02_base_F", 
			[[[[0.813,-3.158,-0.584], [0,0,1]]], AIR_REFUEL_RATE, 2850.0]],

		["Plane_Fighter_03_base_F", 
			[[
				[[0.880,-2.636,-0.939], [1,0,0]],
				[[-0.880,-2.636,-0.939], [-1,0,0]]
			 ], AIR_REFUEL_RATE, 2000.0]],

		["Boat_Transport_02_base_F", 
			[[[[0.061,-2.222,-0.292], [0,0,1]]], BOAT_REFUEL_RATE, 230.0]],

		["Boat_Armed_01_base_F", 
			[[[[0,-3.137,-1.893], [0,-1,0]]], BOAT_REFUEL_RATE, 720.0]],

		["SDV_01_base_F", 
			[[[[-0.093,0.015,-0.473], [0,0,1]]], BOAT_REFUEL_RATE, 30.0]],

		["UGV_01_base_F", 
			[[[[1.134,-0.992,-0.684], [0,0,1]]], ARMOR_REFUEL_RATE, 80.0]]
	];

JBF_R_RetractFuelLine =
{
	private _key = _this select 0;
	if (!local _key) then
	{
		_this remoteExec ["JBF_R_RetractFuelLine", _key];
	}
	else
	{
		params ["_fuelSupply", "_fuelLine"];

		if (ropeUnwound _fuelLine) then
		{
			ropeUnwind [_fuelLine, FUEL_LINE_RETRACT_RATE, 0];

			private _fuelLineDescriptor = _fuelLine getVariable ["JBF_FuelLine", []];
			private _fuelHandle = _fuelLineDescriptor select 1;
			detach _fuelHandle;
			deleteVehicle _fuelHandle;

			// Don't block the caller while we wait for the line to retract
			[_fuelSupply, _fuelLine] spawn
			{
				params ["_fuelSupply", "_fuelLine"];

				scriptName "JBF_R_RetractFuelLine";

				waitUntil { sleep 0.1; ropeUnwound _fuelLine };

				ropeDestroy _fuelLine;

				// If we're using a proxy to host the ropes and that was the last rope, detach from and destroy the proxy
				if (not ((typeOf _fuelSupply) isKindOf "AllVehicles")) then
				{
					private _fuelLines = [_fuelSupply] call JBF_Ropes;
					if (count _fuelLines == 0) then
					{
						private _ropeHost = attachedTo _fuelSupply;
						if (_ropeHost isKindOf ROPE_HOST_PROXY_CLASS) then
						{
							detach _fuelSupply;
							deleteVehicle _ropeHost;
						};
					};
				};
			};
		};
	};
};

/*
	This monitor runs on the server.  Clients start it whenever they create a fuel line.  If a fuel line
	is extended beyond a certain distance, it retracts.  If it is released by whatever is holding it, it
	retracts.  If all lines are retracted, the monitor exits.
*/
JBF_MonitorFuelLines =
{
	if (!canSuspend) then
	{
		_this spawn JBF_MonitorFuelLines;
	}
	else
	{
		params ["_fuelSupply"];

		if (_fuelSupply getVariable ["JBF_MonitorActive", false]) exitWith {};

		_fuelSupply setVariable ["JBF_MonitorActive", true];

		private _fuelLine = objNull;
		private _endPositions = [];
		private _linesExist = false;

		while { true } do
		{
			_linesExist = false;
			{
				_linesExist = true;

				_fuelLine = (_x select 0);

				// Test if fuel line has been extended too far
				_endPositions = ropeEndPosition _fuelLine;
				if ((_endPositions select 0) distance (_endPositions select 1) > FUEL_LINE_RETRACT_DISTANCE) then
				{
					[_fuelSupply, _fuelLine] call JBF_R_RetractFuelLine;
				}
				else
				{
					private _fuelLineDescriptor = _fuelLine getVariable ["JBF_FuelLine", []];
					private _fuelHandle = _fuelLineDescriptor select 1;

					// The rope is sitting in a deployed state, still attached
					if (ropeUnwound _fuelLine && not isNull _fuelHandle) then
					{
						private _holder = attachedTo _fuelHandle;
						if ((typeOf _holder) isKindOf "Man") then
						{
							// Dead or incapacitated player
							if (not (lifeState _holder in ["HEALTHY", "INJURED"])) then
							{
								[_fuelSupply, _fuelLine] call JBF_R_RetractFuelLine;
							};
						}
						else
						{
							// Destroyed vehicle
							if (not alive _holder) then
							{
								[_fuelSupply, _fuelLine] call JBF_R_RetractFuelLine;
							};
						};
					};
				};
			} forEach ([_fuelSupply] call JBF_GetActiveFuelLines);

			if (!_linesExist) exitWith {};

			sleep 1.0;
		};

		_fuelSupply setVariable ["JBF_MonitorActive", nil];
	};
};

JBF_Ropes =
{
	params ["_fuelSupply"];

	if (isNull _fuelSupply) exitWith { [] };

	private _ropeHost = attachedTo _fuelSupply;
	if (not isNull _ropeHost) exitWith { ropes _ropeHost };

	ropes _fuelSupply;
};

// [[rope, fuel-line-index], [rope, fuel-line-index], ...] sorted by fuel-line-index
JBF_GetActiveFuelLines =
{
	params ["_fuelSupply"];

	private _fuelLines = [];
	{
		private _fuelLineDescriptor = _x getVariable ["JBF_FuelLine", []];
		if (count _fuelLineDescriptor > 0) then
		{
			_fuelLines pushBack [_x, _fuelLineDescriptor select 0];
		};
	} forEach ([_fuelSupply] call JBF_Ropes);

	[_fuelLines, nil, { _x select 1 }, "ASCEND"] call BIS_fnc_sortBy;

	_fuelLines;
};

JBF_CreateHandle =
{
	private _fuelHandle = "Land_Can_V2_F" createVehicle [random -10000, random -10000, 1000 + random 10000];
	[_fuelHandle, true] remoteExec ["hideObjectGlobal", 2];
	_fuelHandle allowDamage false;
	_fuelHandle enableSimulation false;

	_fuelHandle;
};

// [closest-index, closest-distance-squared]
JBF_GetClosestFuelLine =
{
	params ["_fuelSupply", "_position", "_mustBeOpen"];

	private _fuelSupplyDescriptor = _fuelSupply getVariable ["JBF_FuelSupply", []];
	private _fuelLineDescriptors = _fuelSupplyDescriptor select 0;

	private _positionModel = _fuelSupply worldToModel _position;

	// Create an array of indices from 0 to (count _fuelLineDescriptors)
	private _fuelLineIndices = [];
	for "_i" from 0 to (count _fuelLineDescriptors) - 1 do
	{
		_fuelLineIndices pushBack _i;
	};

	if (_mustBeOpen) then
	{
		// Pull out any indices used by existing fuel lines
		{
			_fuelLineIndices = _fuelLineIndices - [_x select 1];
		} forEach ([_fuelSupply] call JBF_GetActiveFuelLines);
	};

	// Of the remaining indices, find out which is closest
	private _closestDistance = 1e30;
	private _closestIndex = -1;
	{
		private _fuelLineDistance = (_fuelLineDescriptors select _x) distanceSqr _positionModel;
		if (_fuelLineDistance < _closestDistance) then
		{
			_closestDistance = _fuelLineDistance;
			_closestIndex = _x;
		};
	} forEach _fuelLineIndices;

	[_closestIndex, _closestDistance]
};

JBF_GetFuelLineCondition =
{
	params ["_fuelSupply"];

	if (vehicle player != player) exitWith { false };

	private _closestFuelLine = [_fuelSupply, getPos player, true] call JBF_GetClosestFuelLine;

	(_closestFuelLine select 1) < DISTANCE_FROM_FUEL_LINE_SQR
};

JBF_GetFuelLine =
{
	params ["_fuelSupply"];

	private _fuelSupplyDescriptor = _fuelSupply getVariable ["JBF_FuelSupply", []];
	private _fuelLineDescriptors = _fuelSupplyDescriptor select 0;

	private _fuelRemaining = _fuelSupply getVariable ["JBF_SupplyRemaining", 0];

	if (_fuelRemaining == 0) exitWith { ["Fuel supply is empty", 1] call JB_fnc_showBlackScreenMessage };

	private _closestFuelLine = [_fuelSupply, getPos player, true] call JBF_GetClosestFuelLine;

	private _fuelLineIndex = _closestFuelLine select 0;

	if (_fuelLineIndex == -1) exitWith { ["All available fuel lines are in use", 1] call JB_fnc_showBlackScreenMessage };

	if (not isNull ([player] call JBF_GetHeldFuelHandle)) then
	{
		[player] call JBF_ReleaseAllFuelLines;
	};

	[_fuelSupply, _fuelLineIndex, _fuelLineDescriptors select (_closestFuelLine select 0), player] call JBF_R_GetFuelLine2;
};

#define CHAIN_BEGIN(name) name = { private _key = _this select 0; if (!local _key) then { _this remoteExec [#name, _key] } else
#define CHAIN_END(name) };

JBF_R_GetFuelLine2 =
{
	private _key = _this select 0;
	if (!local _key) then
	{
		_this remoteExec ["JBF_R_GetFuelLine2", _key]
	}
	else
	{
		params ["_fuelSupply", "_fuelLineIndex", "_fuelLinePosition", "_player"];

		private _ropeParent = _fuelSupply;
		if (not ((typeOf _fuelSupply) isKindOf "AllVehicles")) then
		{
			_ropeParent = attachedTo _fuelSupply;
			if (isNull _ropeParent) then
			{
				private _fuelSupplyPosition = getPos _fuelSupply;
				_fuelSupplyPosition set [2, 0];

				_ropeParent = createVehicle [ROPE_HOST_PROXY_CLASS, _fuelSupplyPosition, [], -1, "can_collide"];
				_ropeParent allowDamage false;
				[_ropeParent, true] remoteExec ["hideObjectGlobal", 2];

				_ropeParent setPos _fuelSupplyPosition;

				_ropeParent setDir (getDir _fuelSupply);

				_fuelSupply attachTo [_ropeParent];
			};
		};

		private _fuelLine = ropeCreate [_ropeParent, _fuelLinePosition, FUEL_LINE_LENGTH];

		private _fuelHandle = call JBF_CreateHandle;

		_fuelHandle attachTo [_player, [-0.1, 0.1, 0.15], "Pelvis"];

		[_fuelSupply, _fuelLine, _fuelLineIndex, _player, _fuelHandle, [0,-1,0]] call JBF_R_AttachFuelLine;

		// Start the line monitor on the server
		[_fuelSupply] remoteExec ["JBF_MonitorFuelLines", 2];
	};
};

JBF_R_AttachFuelLine =
{
	private _key = _this select 0;
	if (!local _key) then
	{
		_this remoteExec ["JBF_R_AttachFuelLine", _key]
	}
	else
	{
		params ["_fuelSupply", "_fuelLine", "_fuelLineIndex", "_fuelConsumer", "_fuelHandle", "_direction"];

		_fuelLine setVariable ["JBF_FuelLine", [_fuelLineIndex, _fuelHandle], true]; // global
		_fuelHandle setVariable ["JBF_FuelHandle", [_fuelLine, _fuelSupply], true]; // global

		[_fuelHandle, [0, 0, 0], _direction] ropeAttachTo _fuelLine;
	};
};

JBF_GetHeldFuelHandle =
{
	private _holder = param [0, objNull, [objNull]];
	private _fuelSupply = param [1, objNull, [objNull]]; // optional

	private _heldFuelHandle = objNull;
	{
		private _fuelHandle = _x;

		private _fuelHandleDescriptor = _x getVariable ["JBF_FuelHandle", []];
		if (count _fuelHandleDescriptor > 0 && isNull _fuelSupply) exitWith { _heldFuelHandle = _fuelHandle };
		if (count _fuelHandleDescriptor > 0) then
		{
			{
				if (_fuelHandleDescriptor select 0 == _x) exitWith { _heldFuelHandle = _fuelHandle };
			} forEach ([_fuelSupply] call JBF_Ropes);
		};
	} forEach (attachedObjects _holder);

	_heldFuelHandle;
};

JBF_ReleaseAllFuelLinesCondition =
{
	if (isNull ([player] call JBF_GetHeldFuelHandle)) exitWith { false };

	true;
};

JBF_ReleaseAllFuelLines =
{
	params ["_holder"];

	{
		private _fuelHandleDescriptor = _x getVariable ["JBF_FuelHandle", []];
		if (count _fuelHandleDescriptor > 0) then
		{
			[_fuelHandleDescriptor select 1, _fuelHandleDescriptor select 0] call JBF_R_RetractFuelLine;
		};
	} forEach attachedObjects _holder;
};

JBF_GetClosestFuelPort =
{
	params ["_holder", "_vehicle"];

	private _index = JBF_FuelConsumers findIf { _vehicle isKindOf (_x select 0) };
	if (_index == -1) exitWith { [] };

	private _descriptor = JBF_FuelConsumers select _index select 1;

	private _fuelPorts = _descriptor select 0;

	private _holderModelPosition = _vehicle worldToModel (getPos _holder);

	private _closestFuelPort = [];
	private _closestDistance = 1e30;
	private _direction = [];
	{
		private _fuelPortModelPosition = _x select 0;

		private _inUse = false;
		{
			if (_fuelPortModelPosition distanceSqr (getPos _x) < 0.01) exitWith { _inUse = true }
		} forEach attachedObjects _vehicle;

		if (!_inUse) then
		{
			private _portDistanceSqr = _holderModelPosition distanceSqr _fuelPortModelPosition;
			if ((_portDistanceSqr < DISTANCE_FROM_FUEL_PORT_SQR) && (_portDistanceSqr < _closestDistance)) then
			{
				_closestDistance = _portDistanceSqr;
				_closestFuelPort = _x;
			};
		};
	} forEach _fuelPorts;

	_closestFuelPort;
};

JBF_IsFueling =
{
	params ["_fuelHandle"];

	if (isNull _fuelHandle) exitWith { false };

	if (!alive (attachedTo _fuelHandle)) exitWith { false };

	private _vehicle = attachedTo _fuelHandle;

	if (fuel _vehicle == 1) exitWith { false };

	private _fuelHandleDescriptor = _fuelHandle getVariable ["JBF_FuelHandle", []];
	private _fuelSupply = _fuelHandleDescriptor select 1;

	if (_fuelSupply getVariable ["JBF_SupplyRemaining", 0] == 0) exitWith { false };

	true;
};

JBF_R_TransferFuel =
{
	params ["_vehicle", "_fuelSupply", "_fuelPulse"];

	private _index = JBF_FuelConsumers findIf { _vehicle isKindOf (_x select 0) };
	private _descriptor = JBF_FuelConsumers select _index select 1;
	private _vehicleCapacity = _descriptor select 2;

	private _vehicleCapacityRemaining = (1.0 - (fuel _vehicle)) * _vehicleCapacity;
	private _fuelRemaining = _fuelSupply getVariable ["JBF_SupplyRemaining", 0];

	_fuelPulse = _fuelPulse min _fuelRemaining min _vehicleCapacityRemaining;

	_vehicle setFuel (fuel _vehicle) + (_fuelPulse / _vehicleCapacity);
	_fuelSupply setVariable ["JBF_SupplyRemaining", _fuelRemaining - _fuelPulse, true]; // global;
};

JBF_StopFuelingVehicleCondition =
{
	params ["_vehicle"];

	if (isNull _vehicle) exitWith { false };

	if (getNumber (configFile >> "CfgVehicles" >> typeOf _vehicle >> "fuelCapacity") == 0) exitWith { false };

	private _fuelPort = [player, _vehicle] call JBF_GetClosestFuelPort;
	if (count _fuelPort == 0) exitWith { false };

	private _fuelPortPositionWorld = _vehicle modelToWorld (_fuelPort select 0);

	private _stopFueling = false;
	{
		if (count (_x getVariable ["JBF_FuelHandle", []]) > 0) then
		{
			if (_fuelPortPositionWorld distanceSqr (getPos _x) < 0.01) then
			{
				_stopFueling = true;
			};
		};
	} forEach (attachedObjects _vehicle);

	_stopFueling;
};

JBF_StopFuelingVehicle =
{
	params ["_vehicle"];

	private _fuelPort = [player, _vehicle] call JBF_GetClosestFuelPort;
	private _fuelPortPositionWorld = _vehicle modelToWorld (_fuelPort select 0);

	{
		private _fuelHandleDescriptor = _x getVariable ["JBF_FuelHandle", []];
		if (count _fuelHandleDescriptor > 0) then
		{
			if (_fuelPortPositionWorld distanceSqr (getPos _x) < 0.01) then
			{
				[_fuelHandleDescriptor select 1, _fuelHandleDescriptor select 0] call JBF_R_RetractFuelLine;
			};
		};
	} forEach (attachedObjects _vehicle);
};

JBF_FuelVehicleCondition =
{
	params ["_vehicle"];

	if (isNull _vehicle) exitWith { false };

	if (vehicle player != player) exitWith { false };

	if (getNumber (configFile >> "CfgVehicles" >> typeOf _vehicle >> "fuelCapacity") == 0) exitWith { false };

	if (isNull ([player] call JBF_GetHeldFuelHandle)) exitWith { false };

	// Allow unknown vehicles to immediately register so the player can be informed
	if ((JBF_FuelConsumers findIf { _vehicle isKindOf (_x select 0) }) == -1) exitWith { true };

	if (count ([player, _vehicle] call JBF_GetClosestFuelPort) == 0) exitWith { false };

	true;
};

JBF_FuelVehicle =
{
	params ["_holder", "_vehicle"];

	if ((JBF_FuelConsumers findIf { _vehicle isKindOf (_x select 0) }) == -1) exitWith
	{
		private _message = format ["%1 does not accept any available fuel types", [typeOf _vehicle, "CfgVehicles"] call JB_fnc_displayName];
		[_message, 1] call JB_fnc_showBlackScreenMessage;
	};

	private _fuelLine = objNull;
	private _fuelSupply = objNull;
	private _fuelHandle = objNull;
	{
		private _fuelHandleDescriptor = _x getVariable ["JBF_FuelHandle", []];
		if (count _fuelHandleDescriptor > 0) then
		{
			_fuelHandle = _x;
			_fuelLine = _fuelHandleDescriptor select 0;
			_fuelSupply = _fuelHandleDescriptor select 1;
		};
	} forEach attachedObjects _holder;

	[_fuelSupply, _fuelLine, _fuelHandle, _holder, _vehicle] remoteExec ["JBF_R_FuelVehicle2", _fuelSupply];
};

JBF_R_FuelVehicle2 =
{
	params ["_fuelSupply", "_fuelLine", "_fuelHandle", "_holder", "_vehicle"];

	private _fuelPort = [_holder, _vehicle] call JBF_GetClosestFuelPort;

	private _fuelLineIndex = (_fuelLine getVariable ["JBF_FuelLine", []]) select 0;

	// Transfer the fuel handle from player to vehicle
	_fuelHandle attachTo [_vehicle, _fuelPort select 0];

	[_holder, _vehicle, _fuelHandle, _fuelSupply, _fuelLine] spawn
	{
		params ["_holder", "_vehicle", "_fuelHandle", "_fuelSupply", "_fuelLine"];

		scriptName "JBF_R_FuelVehicle2";

		private _fuelSupplyDescriptor = _fuelSupply getVariable ["JBF_FuelSupply", []];
		private _index = JBF_FuelConsumers findIf { _vehicle isKindOf (_x select 0) };
		private _vehicleDescriptor = JBF_FuelConsumers select _index select 1;

		private _fuelSupplyRate = _fuelSupplyDescriptor select 2;
		private _vehicleRate = _vehicleDescriptor select 1;

		private _refuelRate = _fuelSupplyRate min _vehicleRate;

		_fuelSupply engineOn true;

		private _engineMustStayOn = getNumber (configFile >> "CfgVehicles" >> typeOf _fuelSupply >> "fuelCapacity") > 0;

		while { [_fuelHandle] call JBF_IsFueling && { not _engineMustStayOn || { isEngineOn _fuelSupply } } } do
		{
			_availableFuel = _fuelSupply getVariable ["JBF_SupplyRemaining", 0];

			_fuelPulse = (_refuelRate * FUEL_UPDATE_INTERVAL) min _availableFuel;

			[_vehicle, _fuelSupply, _fuelPulse] remoteExec ["JBF_R_TransferFuel", _vehicle];

			sleep FUEL_UPDATE_INTERVAL;
		};

		[_fuelSupply, _fuelLine] call JBF_R_RetractFuelLine;
	};
};

JBF_LoadFuelSupply =
{
	if (not isServer) then
	{
		_this remoteExec ["JBF_LoadFuelSupply", 2];
	}
	else
	{
		params ["_vehicle", "_fuel"];

		private _fuelCapacity = _vehicle getVariable ["JBF_SupplyCapacity", 0];
		private _fuelRemaining = _vehicle getVariable ["JBF_SupplyRemaining", 0];

		_fuelRemaining = (_fuelRemaining + _fuel) min _fuelCapacity;

		_vehicle setVariable ["JBF_SupplyRemaining", _fuelRemaining, true]; // global
	};
};

JBF_SetupClient =
{
	private _unit = param [0, objNull, [objNull]];
	private _fuelLinePositions = param [1, [], [[]]];
	private _fuelCapacity = param [2, 1000, [0]];
	private _fuelFlowRate = param [3, 4.5, [0]];

	if (not alive _unit) exitWith {};

	_unit setVariable ["JBF_FuelSupply", [_fuelLinePositions, _fuelCapacity, _fuelFlowRate], true];

	if (not hasInterface) exitWith {};

	_unit addAction ["<t color='#FFFF99'>Get fuel line</t>", { [_this select 0] call JBF_GetFuelLine }, nil, 10, false, true, "", "[cursorObject] call JBF_GetFuelLineCondition"];
};