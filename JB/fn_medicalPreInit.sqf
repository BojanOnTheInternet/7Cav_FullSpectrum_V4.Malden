#include "..\OO\oo.h"

// Distance bodies are moved from a destroyed vehicle
JBM_DISTANCE_FROM_DESTROYED_VEHICLE = 10;
// Frequency of medic monitor basic updates (seconds)
JBM_MONITOR_POLL_INTERVAL = 0.5;
// Frequency of medic monitor full updates (seconds)
JBM_MONITOR_FULL_INTERVAL = 3.0;
// Distance monitor will detect medics (meters)
JBM_MONITOR_RANGE = 500;
// Number of medics monitor will list (count) - must be matched against UI design
JBM_MONITOR_NUMBER_MEDICS = 5;
// Maximum time to bleedout after being incapacitated (seconds)
JBM_MAX_BLEEDOUT_TIME = 600;
// Frequency of updates to the player's damage-based bleedout time (seconds)
JBM_BLEEDOUT_UPDATE_INTERVAL = 3.0;
// Distance at which medical assistance can be performed
JBM_MEDICAL_ACTION_DISTANCE = 3;
// The bleedout pace of an unstabilized wound
JBM_UNSTABILIZED_BLEEDOUT_PACE = 1;
// The bleedout pace of a stabilized wound
JBM_STABILIZED_BLEEDOUT_PACE = 0.01;
// The minimum time that an ambulance revive can take
JBM_MINIMUM_AMBULANCE_REVIVE_TIME = 4;
// The time it takes for an ambulance to stabilize a patient
JBM_AMBULANCE_STABILIZE_TIME = 3;

// The speed at which the "roll over" animation should run when revived
JBM_REVIVE_ANIMATION_ACCELERATION = 1.6;

// The range of player numbers used to ramp the self-revive delay
JBM_START_REVIVE_SELF_COUNT = 1;
JBM_END_REVIVE_SELF_COUNT = 30;

// The range of times (in seconds) used to ramp the self-revive delay
JBM_START_REVIVE_SELF_TIME = 5;
JBM_END_REVIVE_SELF_TIME = 90;

// Acts_CivilInjured* is a great series of downed animations specific to body parts
// Acts_Injured*Rifle01
// Acts_TreatingWounded*

JBM_R_ShowFriendlyFireWarning =
{
	["FRIENDLY FIRE", 1] call JB_fnc_showBlackScreenMessage
};

JBM_AmmoMagazineWeapon =
{
	params ["_ammo", "_weapons"];

	private _weapon = "";
	private _magazine = "";

	scopeName "function";
	{
		_weapon = _x;

		{
			_magazine = _x;
			if (getText (configFile >> "CfgMagazines" >> _magazine >> "ammo") == _ammo) then { breakTo "function" };
		} forEach getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines");

		// It's not a round from the primary barrel, so check for secondary barrels.  Known variations include "EGLM", "Secondary" and "GL_3GL_F"
		{
			{
				_magazine = _x;
				if (getText (configFile >> "CfgMagazines" >> _magazine >> "ammo") == _ammo) then { breakTo "function" };
			} forEach getArray (_x >> "magazines");
		} forEach configProperties [(configFile >> "CfgWeapons" >> _weapon), "isClass _x",true];

		_magazine = "";
	} forEach _weapons;

	if (_magazine == "") exitWith { ["", ""] };

	private _magazineName = getText (configFile >> "CfgMagazines" >> _magazine >> "displayName");
	private _weaponName = getText (configFile >> "CfgWeapons" >> _weapon >> "displayName");

	[_magazineName, _weaponName]
};

JBM_WeaponDescription =
{
	params ["_vehicle", "_gunner", "_ammo"];

	if (_ammo == "") exitWith { "" };

	private _magazineWeapon = ["", ""];

	if (_vehicle isKindOf "Man") then
	{
		_magazineWeapon = [_ammo, weapons _vehicle + ["Put", "Throw"]] call JBM_AmmoMagazineWeapon;
	}
	else
	{
		private _gunnerCrew = (fullCrew _vehicle) select { (_x select 0) == _gunner };
		if (count _gunnerCrew == 0) then
		{
			_magazineWeapon = [_ammo, weapons _vehicle] call JBM_AmmoMagazineWeapon;
		}
		else
		{
			// If _gunnerCrew select 0 select 4 is true, then it's a person shooting from a vehicle
			if (_gunnerCrew select 0 select 1 == "Turret" && (_gunnerCrew select 0 select 4)) then
			{
				_magazineWeapon = [_ammo, weapons (_gunnerCrew select 0 select 0) + ["Put", "Throw"]] call JBM_AmmoMagazineWeapon;
			}
			else
			{
				private _turret = _gunnerCrew select 0 select 3;
				_magazineWeapon = [_ammo, _vehicle weaponsTurret _turret] call JBM_AmmoMagazineWeapon;
			};
		};
	};

	if (_magazineWeapon select 1 in ["Put", "Throw"]) exitWith { _magazineWeapon select 0 };

	(_magazineWeapon select 1) + " (loaded with " + (_magazineWeapon select 0) + ")";
};

JBM_SelectionDescription =
{
	params ["_selection"];

	private _description = "";
	{
		if (getText (_x >> "name") == _selection) exitWith
		{
			_description = toLower ((configName _x) select [3]);
		};
	} forEach ("true" configClasses (configFile >> "CfgVehicles" >> "SoldierWB" >> "HitPoints"));

	_description;
};

JBM_DirectionDescription =
{
	params ["_wounded", "_source"];

	private _direction = (_wounded getRelDir _source) / 45.0;

	["the front", "the right", "the right", "behind", "behind", "the left", "the left", "the front"] select (floor _direction);
};

JBM_FactionShooter =
{
	params ["_shooter"];

	private _description = "";
	private _unitType = getText (configFile >> "CfgVehicles" >> typeOf _shooter >> "displayName");
	switch (true) do
	{
		case (damage _shooter == 1): { _description = "a " + _unitType };
		case (playerSide getFriend side _shooter >= 0.6): { _description = "a friendly " + _unitType };
		default { _description = "an enemy " + _unitType };
	};

	_description;
};

JBM_ShooterDescription =
{
	params ["_source", "_instigator"];

	private _description = "";

	if (isNull _instigator) then
	{
		// Indirect damage
		if (isPlayer _source) then
		{
			_description = name _source;
		}
		else
		{
			_description = [_source] call JBM_FactionShooter;
		}
	}
	else
	{
		// Direct damage (side check is to ensure curators don't get identified when operating enemy units)
		//BUG: Curator operating friendly unit is reported as "enemy"
		if (isPlayer _instigator && side _source == side _instigator) then
		{
			if (_source isKindOf "Man") then
			{
				_description = name _instigator;
			}
			else
			{
				private _vehicleType = getText (configFile >> "CfgVehicles" >> typeOf _source >> "displayName");
				_description = name _instigator + " using a " + _vehicleType;
			};
		}
		else
		{
			_description = [_source] call JBM_FactionShooter;
		};
	};

	_description;
};

// Reports new damage levels to various parts of the body.  Note that some parts are composites of other parts.  To calculate
// the amount of ADDITIONAL damage due to the call, use "_damage - (_wounded getHitIndex _partIndex)"
JBM_HandleDamage =
{
	params ["_wounded", "_selection", "_damage", "_source", "_projectile", "_partIndex", "_instigator"];

	if (lifeState _wounded in ["DEAD", "DEAD-RESPAWN"]) exitWith {};

	// The -1 index is reporting a setDamage value.  The instigator check is establishing that somebody is shooting at us.  That means
	// that setDamage is going to go up with every hit, killing the player outright instead of incapacitating him.  So we disable setDamage
	// and rely on our detection of incapacitation below.
	if (_partIndex == -1 && not isNull _instigator) then
	{
		_damage = _wounded getHitIndex _partIndex;
	}
	else
	{
		_wounded setVariable ["JBM_Stabilized", nil, true];
		_wounded setVariable ["JBM_Rewounded", true];

		private _friendlyFire = isPlayer _instigator && { side _instigator == side _wounded } && { _instigator != _wounded };

		if (_friendlyFire) then
		{
			[] remoteExec ["JBM_R_ShowFriendlyFireWarning", _instigator];
		};

		// Player on foot hit by a friendly vehicle suffers no damage (but is destabilized).  _wounded == _source means the player fell
		if (vehicle _wounded == _wounded && isNull _instigator && (_wounded != _source) && (isNull _source || side _source == side _wounded) && _projectile == "") then
		{
			_damage = _wounded getHitIndex _partIndex;
		}
		else
		{
			if (_wounded getVariable ["JBM_Incapacitated", false]) then
			{
				_damage = _damage min 0.9;
			}
			else
			{
				private _incapacitate = false;

				if (_partIndex == -1) then
				{
					_incapacitate = (_damage > 0.9);
					_damage = _damage min 0.9;
				}
				else
				{
					if (_damage > 0.9) then
					{
						_damage = 0.9;
						if (not (_selection in ["arms", "legs", "hands"])) then { _incapacitate = true };
					};
				};

				if (_incapacitate) then
				{
					_wounded setVariable ["JBM_Incapacitated", true];

					[_wounded, _selection, _source, _projectile, _instigator] spawn
					{
						params ["_wounded", "_selection", "_source", "_projectile", "_instigator"];

						scriptName "JBM_HandleDamage";

						if (_source == _wounded) then
						{
							systemchat "You incapacitated yourself";
						}
						else
						{
							if (isNull _source) then
							{
								systemchat "You were incapacitated by a series of unfortunate events";
							}
							else
							{
								private _locationDescription = if (_selection == "") then { " by a hit" } else { " by a hit to the " + ([_selection] call JBM_SelectionDescription) };
								private _directionDescription = " from " + ([_wounded, _source] call JBM_DirectionDescription);
								private _shooterDescription = " by " + ([_source, _instigator] call JBM_ShooterDescription);

								if (_projectile != "") then
								{
									_shooterDescription = _shooterDescription + "'s " + ([_source, _instigator, _projectile] call JBM_WeaponDescription);
								};

								systemchat format ["You were incapacitated%1%2%3", _locationDescription, _directionDescription, _shooterDescription];
							};
						};
					};

					private _friendlyFireMessage = if (not _friendlyFire) then { "" } else { format [" (friendly fire from %1)", [_source, _instigator] call JBM_ShooterDescription] };
					(format ["%1 is down and needs a medic%2", name _wounded, _friendlyFireMessage]) remoteExec ["systemChat", 0];
			
					private _woundedVehicle = vehicle _wounded;
					if (_woundedVehicle == _wounded) then
					{
						[_wounded] call JBM_Incapacitate; // On foot
					}
					else
					{
						if (not alive _woundedVehicle || _woundedVehicle isKindOf "StaticWeapon") then
						{
							moveOut _wounded; // In destroyed vehicle or static weapon

							[_wounded] call JBM_Incapacitate;

							if (not (_woundedVehicle isKindOf "StaticWeapon")) then
							{
								[_wounded] call JBM_EjectIncapacitated;
							};
						}
						else
						{
							// Everyone is incapacitated in the vehicle (which is on the ground), so eject everyone to let them self-revive
							if (isTouchingGround _woundedVehicle && { { isPlayer _x && { lifeState _x in ["HEALTHY", "INJURED"] } } count crew _woundedVehicle == 1 }) then
							{
								[_wounded] call JBM_Incapacitate;
								{
									[_x] remoteExec ["JBM_EjectIncapacitated", _x];
								} forEach crew _woundedVehicle;
							}
							else
							{
								// If the player is the driver, handle that separately
								if (_wounded == driver _woundedVehicle && _woundedVehicle != _wounded) then
								{
									[_wounded] spawn JBM_IncapacitateDriver;
								}
								// Otherwise, incapacitate as normal but make sure the character is shown slumped in the vehicle
								else
								{
									[_wounded] call JBM_Incapacitate;
									[_wounded, "unconscious"] remoteExec ["playMoveNow"];
								};
							};
						};
					};
				};
			};
		};
	};

	_damage
};

JBM_EjectIncapacitated =
{
	params ["_wounded"];

	private _clearDistance = (boundingBoxReal vehicle _wounded) select 1;
	_clearDistance = (_clearDistance select 0) max (_clearDistance select 1) max (_clearDistance select 2);

	private _direction = random 360;
	private _away = [cos _direction, sin _direction, 0.5];
	_wounded setPos ((getPos vehicle _wounded) vectorAdd (_away vectorMultiply _clearDistance));
	_wounded setVelocity (_away vectorMultiply 5);
};

JBM_IncapacitateDriver =
{
	params ["_wounded"];

	private _vehicle = vehicle _wounded;

	moveOut _wounded;
	sleep 0.2;

	{
		if (isNull (_x select 0) && (_x select 1) != "driver") exitWith
		{
			switch (_x select 1) do
			{
				case "gunner":
				{
					_wounded moveInGunner _vehicle;
				};
				case "commander":
				{
					_wounded moveInCommander _vehicle;
				};
				case "Turret":
				{
					_wounded moveInTurret [_vehicle, _x select 3];
				};
				case "cargo":
				{
					_wounded moveInCargo _vehicle;
				};
			}
		};
	} forEach fullCrew [_vehicle, "", true];

	[_wounded] call JBM_Incapacitate;
	[_wounded, "unconscious"] remoteExec ["playMoveNow"]; // Make character slump in seat
};

JBM_S_LogIncapacitation =
{
	params ["_wounded"];

	diag_log format ["INCAPACITATED: %1, (%2), (%3)", getPos _wounded, typeOf _wounded, typeOf vehicle _wounded];
};

JBM_Incapacitate =
{
	params ["_wounded"];

	[_wounded] remoteExec ["JBM_S_LogIncapacitation", 2];

	_wounded setUnconscious true;
	_wounded setCaptive true;
	_wounded action ["SwitchWeapon", _wounded, _wounded, -1];

	[_wounded] spawn JBM_MedicMonitor;
};

JBM_NearbyMedics =
{
	params ["_wounded", "_range"];

	private _medics = [];
	{
		{
			if (_x != _wounded && { (lifeState _x) in ["HEALTHY", "INJURED", "INCAPACITATED"] } && { _x getUnitTrait "medic" } && { isPlayer _x }) then { _medics pushBack _x };
		} forEach crew _x;
	} forEach (_wounded nearEntities ["AllVehicles", _range]);

	_medics;
};

JBM_HideMedicMonitor =
{
	params ["_wounded"];

	"JBM_MedicMonitorLayer" cutText ["", "plain"];

	_wounded setUserActionText [JBM_MedicMonitorAction, "Show medic list"];

	JBM_MedicMonitorFields = [];
};

JBM_ShowMedicMonitor =
{
	params ["_wounded"];

	"JBM_MedicMonitorLayer" cutRsc ["JBM_MedicMonitor", "plain"];
	disableSerialization;

	private _medicMonitor = uiNamespace getVariable "JBM_MedicMonitor";

	_medicList = _medicMonitor displayCtrl 1200;
	_additionalInformation = _medicMonitor displayCtrl 1300;
	_bleedoutDisplay = _medicMonitor displayCtrl 1400;

	_wounded setUserActionText [JBM_MedicMonitorAction, "Hide medic list"];

	JBM_MedicMonitorFields = [_medicList, _additionalInformation, _bleedoutDisplay];

	[_wounded, 0] call JBM_UpdateMedicMonitor;
};

JBM_ToggleMedicMonitor =
{
	params ["_wounded"];

	if (count JBM_MedicMonitorFields > 0) then
	{
		[_wounded] call JBM_HideMedicMonitor;
	}
	else
	{
		[_wounded] call JBM_ShowMedicMonitor;
	};
};

JBM_UpdateMedicMonitor =
{
	params ["_wounded", "_bleedoutTime"];

	private _medicList = JBM_MedicMonitorFields select 0;
	private _additionalInformation = JBM_MedicMonitorFields select 1;
	private _bleedoutDisplay = JBM_MedicMonitorFields select 2;

	_bleedoutDisplay ctrlSetText ([round (_bleedoutTime max 0), "MM:SS"] call BIS_fnc_secondsToString);

	if ((round time) mod JBM_MONITOR_FULL_INTERVAL == 0) then
	{
		lbClear _medicList;

		private _medics = [_wounded, JBM_MONITOR_RANGE] call JBM_NearbyMedics;
		{
			_medicList lnbAddRow [name _x, format ["%1m", round (_wounded distance _x)], format ["%1", lifeState _x]];
		} forEach (_medics select [0, JBM_MONITOR_NUMBER_MEDICS]);

		private _message = "";

		if (count _medics == 0) then
		{
			_message = format ["No medics within %1 meters", JBM_MONITOR_RANGE];
		}
		else
		{
			private _extraMedics = count _medics - JBM_MONITOR_NUMBER_MEDICS;
			if (_extraMedics > 0) then
			{
				_message = format ["%1 other medics not listed", _extraMedics];
			};
		};

		if ((["ReviveSelf"] call JB_MP_GetParamValue) == 1) then
		{
			if (diag_tickTime > JBM_ReviveSelfTime) then
			{
				_message = format ["%1 (Revive self available)", _message];
			}
			else
			{
				_message = format ["%1 (Revive self available in %2)", _message, [ceil (JBM_ReviveSelfTime - diag_tickTime), "MM:SS"] call BIS_fnc_secondsToString];
			};
		};

		_additionalInformation ctrlSetText _message;
	};
};

JBM_ComputeBleedoutTime =
{
	params ["_wounded"];

	private _selections = (getAllHitPointsDamage _wounded) select 2;
	private _timePerSelection = JBM_MAX_BLEEDOUT_TIME / (count _selections);
	private _bleedoutTime = 0;
	{
		_bleedoutTime = _bleedoutTime + ((0.92 - _x) * _timePerSelection);
	} forEach _selections;

	_bleedoutTime;
};

JBM_ReviveSelf =
{
	if (not ([player] call JBM_FirstAidKitAvailable)) exitWith { ["'Revive self' requires a first aid kit", 1] call JB_fnc_showBlackScreenMessage };

	if (not ([player] call JBM_ReviveWoundedPossible)) exitWith { ["'Revive self' is not available while in a vehicle or while being moved", 1] call JB_fnc_showBlackScreenMessage };
	
	[objNull, false, 0.25] call JBM_R_HaveBeenRevived
};

JBM_MedicMonitor =
{
	params ["_wounded"];

	private _bleedoutTime = [_wounded] call JBM_ComputeBleedoutTime;
	private _bleedoutCountdown = _bleedoutTime;

	JBM_MedicMonitorFields = [];
	if (not isNil "JBM_MedicMonitorAction") then { diag_log "JBM_MedicMonitor: a non-nil JBM_MedicMonitorAction value is being overwritten." };
	JBM_MedicMonitorAction = _wounded addAction ["Toggle medic list", { [_this select 0] call JBM_ToggleMedicMonitor }, nil, 0, false, true, "", "", -1, true];
	private _respawnAction = _wounded addAction ["Respawn", { if (["Do you really want to respawn?", "RESPAWN", true, true, findDisplay 46] call BIS_fnc_guiMessage) then { (_this select 0) setDamage 1 } }, nil, 0, false, true, "", "", -1, true];

	private _reviveDelay = 1e30;
	private _reviveAction = -1;
	if ((["ReviveSelf"] call JB_MP_GetParamValue) == 1) then
	{
		_reviveDelay = linearConversion [JBM_START_REVIVE_SELF_COUNT, JBM_END_REVIVE_SELF_COUNT, (count (allPlayers select { not (_x isKindOf "HeadlessClient_F") })), JBM_START_REVIVE_SELF_TIME, JBM_END_REVIVE_SELF_TIME, true];
		if (not (_wounded getUnitTrait "medic")) then { _reviveDelay = _reviveDelay * 1.2 };
		JBM_ReviveSelfTime = diag_tickTime + _reviveDelay;
		_reviveAction = _wounded addAction ["Revive self", { [] call JBM_ReviveSelf }, nil, 0, false, true, "", "diag_tickTime > JBM_ReviveSelfTime", -1, true];
	};

	[_wounded] call JBM_ShowMedicMonitor;

	while { lifeState _wounded == "INCAPACITATED" } do
	{
		// If the _wounded has taken more damage, shorten the bleedout time appropriately and destabilize the patient
		if (_wounded getVariable ["JBM_Rewounded", false]) then
		{
			private _bleedoutTimeUpdated = [_wounded] call JBM_ComputeBleedoutTime;
			_bleedoutCountdown = _bleedoutCountdown - (_bleedoutTime - _bleedoutTimeUpdated);
			_bleedoutTime = _bleedoutTimeUpdated;

			_wounded setVariable ["JBM_Rewounded", nil];
		};

		// Check to see if the soldier bled out
		if (round _bleedoutCountdown <= 0) exitWith
		{
			_wounded setVariable ["JBM_BledOut", true];
			_wounded setDamage 1;
		};

		// If the incapacitated player's vehicle is destroyed, get him out.  We don't rely on the vehicle's Killed event because we also have to pick up
		// cases where the player is incapacitated as the vehicle is being destroyed.  We won't be able to get the vehicle Killed event handler in place
		// before the vehicle Killed event arrives.  So we just poll.
		if (vehicle _wounded != _wounded && not alive vehicle _wounded) then
		{
			[_wounded] call JBM_EjectIncapacitated;
		};

		if (count JBM_MedicMonitorFields > 0) then
		{
			[_wounded, _bleedoutCountdown] call JBM_UpdateMedicMonitor;
		};

		sleep JBM_MONITOR_POLL_INTERVAL;

		// Advance the bleedout timer
		private _pace = if (_wounded getVariable ["JBM_Stabilized", false]) then { JBM_STABILIZED_BLEEDOUT_PACE } else { JBM_UNSTABILIZED_BLEEDOUT_PACE };
		_bleedoutCountdown = _bleedoutCountdown - JBM_MONITOR_POLL_INTERVAL * _pace;

		_wounded setVariable ["JBM_BleedoutCountdown", _bleedoutCountdown];
	};

	_wounded removeAction JBM_MedicMonitorAction;
	_wounded removeAction _respawnAction;

	if (_reviveAction != -1) then { _wounded removeAction _reviveAction };

	[_wounded] call JBM_HideMedicMonitor;

	JBM_MedicMonitorFields = nil;
	JBM_MedicMonitorAction = nil;
	JBM_ReviveSelfTime = nil;
};

JBM_MortalityQuotes =
[
	["No one can say that death found in me a willing comrade, or that I went easily.", "Cassandra Clare, Clockwork Princess"],
	["On a long enough time line, the survival rate for everyone drops to zero.", "Chuck Palahniuk, Fight Club"],
	["Yes, man is mortal, but that would be only half the trouble. The worst of it is that he's sometimes unexpectedly mortal�there's the trick!", "Mikhail Bulgakov, The Master and Margarita"],
	["Man is mortal, and as the professor so rightly said mortality can come so suddenly", "Mikhail Bulgakov, The Master and Margarita"],
	["Your days are numbered. Use them to throw open the windows of your soul to the sun. If you do not, the sun will soon set, and you with it.", "Marcus Aurelius, The Emperor's Handbook"],
	["Time is a great teacher, but unfortunately it kills all its students.", "Hector Berlioz"],
	["Death, only death, can break the lasting chain;<br/>And here, ev'n then, shall my cold dust remain", "Alexander Pope, Eloisa to Abelard"],
	["It's probably a merciful thing that pain is impossible to describe from memory", "Christopher Hitchens, Mortality"],
	["This is to be mortal, And seek the things beyond mortality.", "Lord Byron"],
	["For dust thou art, and into dust thou shalt return", "Genesis 3:19"],
	["Those who do not know how to live must make a merit of dying.", "George Bernard Shaw"],
	["Every leaf before it falls must think itself immortal.", "Marty Rubin"],
	["No matter how well you steer your boat, the big waves catches you in the end.", "Marty Rubin"],
	["Of all the elements in the periodic table, not a single one is indestructible.", "Marty Rubin"],
	["Life is a debt, of which death is our repayment.", "Max Gladstone, Last First Snow"],
	["When mortality is the equation, we are but pawns in a game.", "Dianna Hardy, Reign Of The Wolf"],
	["You need to be greedy or ignorant to truly want to live forever.", "Mokokoma Mokhonoana"],
	["Embrace death, dance with it a while, and finally fall prey to it.", "Darren Shan, Bec"],
	["To die trying is the proudest human thing.", "Robert A. Heinlein, Have Space Suit�Will Travel"],
	["There are some fights none of us can win.", "Amy Rae Durreson, Reawakening"],
	["It is the way of mortals. They fling themselves at life and emerge broken.", "Patricia Briggs, Fair Game"],
	["Mortality is one of the greatest gifts ever bestowed. After a long and fruitful life, we are able to rest.", "Nancy Straight, Blood Debt"]
];

JBM_GetMortalityQuote =
{
	private _quote = selectRandom JBM_MortalityQuotes;

	format ["<t size='1.4'>�%1�</t><br/><br/><t color='#AAAAAA'>--%2</t>", _quote select 0, _quote select 1]
};

JBM_MedicalCleanup =
{
	params ["_unit"];

	detach _unit;
	_unit setCaptive false;

	_unit setVariable ["JBM_Incapacitated", nil];
	_unit setVariable ["JBM_Stabilized", nil, true];
	_unit setVariable ["JBM_Rewounded", nil];
	_unit setVariable ["JBM_BleedoutCountdown", nil];
	_unit setVariable ["JBM_BledOut", nil];
};

JBM_Respawned =
{
	params ["_newBody", "_oldBody"];

	[_oldBody] call JBM_MedicalCleanup;
	[_newBody] call JBM_MedicalCleanup;
	[_newBody] call JBM_SetupActions;
};

JBM_Killed =
{
	params ["_unit", "_killer", "_instigator", "_useEffects"];

	private _end = if (_unit getVariable ["JBM_BledOut", false]) then { "died" } else { "respawned" };
	private _quote = if (_end == "respawned") then { "" } else { call JBM_GetMortalityQuote };
	titleText [_quote, "black out", 0.1, true, true]; // Fade to black.  When the player respawns, the black screen is automatically cleared.

	(format ["%1 has %2", name _unit, _end]) remoteExec ["systemchat", 0];

	[_unit] call JBM_MedicalCleanup;
};

JBM_FirstAidKitAvailable =
{
	params ["_unit"];

	if ("FirstAidKit" in uniformItems _unit) exitwith { true };
	if ("FirstAidKit" in vestItems _unit) exitwith { true };
	if ("FirstAidKit" in backpackItems _unit) exitwith { true };

	false
};

JBM_ConsumeFirstAidKit =
{
	params ["_unit"];

	if ("FirstAidKit" in uniformItems _unit) exitwith { _unit removeItemFromUniform "FirstAidKit"; true };
	if ("FirstAidKit" in vestItems _unit) exitwith { _unit removeItemFromVest "FirstAidKit"; true };
	if ("FirstAidKit" in backpackItems _unit) exitwith { _unit removeItemFromBackpack "FirstAidKit"; true };

	false
};

JBM_ConsumeAmbulanceFirstAidKit =
{
	params ["_ambulance"];

	private _itemCargo = getItemCargo _ambulance;
	private _itemNames = _itemCargo select 0;
	private _itemCounts = _itemCargo select 1;

	private _firstAidKitIndex = _itemNames find "FirstAidKit";

	if (_firstAidKitIndex == -1) exitWith { false };

	private _firstAidKitCount = _itemCounts select _firstAidKitIndex;
	_itemCounts set [_firstAidKitIndex, _firstAidKitCount - 1];

	clearItemCargoGlobal _ambulance;
	for "_i" from 0 to (count _itemNames) - 1 do
	{
		_ambulance addItemCargoGlobal [_itemNames select _i, _itemCounts select _i];
	};

	true
};

JBM_AmbulanceRevive =
{
	params ["_ambulance", "_wounded"];

	private _usedAmbulanceFirstAidKit = false;

	private _reviveTime = _ambulance getVariable "JBM_AmbulanceReviveTime";
	if (isNil "_reviveTime") exitWith {};

	private _bleedoutCountdown = _wounded getVariable "JBM_BleedoutCountdown";
	if (isNil "_bleedoutCountdown") exitWith {};

	_reviveTime = (_reviveTime * (1 - (_bleedoutCountdown / JBM_MAX_BLEEDOUT_TIME))) max JBM_MINIMUM_AMBULANCE_REVIVE_TIME;

	if (_bleedoutCountdown < JBM_AMBULANCE_STABILIZE_TIME min _reviveTime) exitWith
	{
		["Your condition is too serious.  There's nothing that can be done.", 2] remoteExec ["JB_fnc_showBlackScreenMessage", _wounded];
	};

	if (JBM_AMBULANCE_STABILIZE_TIME < _reviveTime && _bleedoutCountdown < _reviveTime && not (player getVariable ["JBM_Stabilized", false])) then
	{
		_usedAmbulanceFirstAidKit = [_ambulance] call JBM_ConsumeAmbulanceFirstAidKit;
		if (not _usedAmbulanceFirstAidKit && not ([player] call JBM_FirstAidKitAvailable)) exitWith
		{
			["You cannot be stabilized because neither you nor the vehicle has a first aid kit.", 1] remoteExec ["JB_fnc_showBlackScreenMessage", _wounded];
		};

		[["Stabilizing critically-wounded patient...", "plain down", 0.5]] remoteExec ["titleText", _wounded];
		sleep JBM_AMBULANCE_STABILIZE_TIME;
		if (alive _ambulance && vehicle _wounded == _ambulance && lifeState _wounded == "INCAPACITATED") then
		{
			[_ambulance, _usedAmbulanceFirstAidKit] remoteExec ["JBM_R_HaveBeenStabilized", _wounded];
		};
	};

	if (not alive _ambulance || vehicle _wounded != _ambulance || lifeState _wounded != "INCAPACITATED") exitWith {};

	_usedAmbulanceFirstAidKit = [_ambulance] call JBM_ConsumeAmbulanceFirstAidKit;
	if (not _usedAmbulanceFirstAidKit && not ([player] call JBM_FirstAidKitAvailable)) exitWith
	{
		["You cannot be revived because neither you nor the vehicle has a first aid kit.", 1] remoteExec ["JB_fnc_showBlackScreenMessage", _wounded];
	};

	[["Reviving wounded patient...", "plain down", 0.5]] remoteExec ["titleText", _wounded];

	sleep _reviveTime;

	if (not alive _ambulance || lifeState _wounded != "INCAPACITATED" || vehicle _wounded != _ambulance) exitWith {};

	[_ambulance, _usedAmbulanceFirstAidKit] remoteExec ["JBM_R_HaveBeenRevived", _wounded];
};

JBM_C_AmbulanceSetupClient =
{
	params ["_ambulance", "_reviveTime"];

	_ambulance setVariable ["JBM_AmbulanceReviveTime", _reviveTime];

	_ambulance addEventHandler ["GetIn",
		{
			params ["_ambulance", "_position", "_wounded"];

			if (_position != "cargo") exitWith {};

			if (lifeState _wounded != "INCAPACITATED") exitWith {};

			[_ambulance, _wounded] spawn JBM_AmbulanceRevive;
		}];
};

JBM_MergeAnimationStates =
{
	params ["_animationState", "_replacements"]; // [[state, [component, ...], ...]

	private _componentState = "";
	private _stateSegment = [0,0];

	{
		_componentState = (_x select 0);
		{
			switch (_x) do
			{
				case "A": { _stateSegment = [1, 3] };
				case "P": { _stateSegment = [5, 3] };
				case "M": { _stateSegment = [9, 3] };
				case "S": { _stateSegment = [13, 3] };
				case "W": { _stateSegment = [17, 3] };
				case "D": { _stateSegment = [21, 3] };
			};

			_state = _componentState select _stateSegment;
			_animationState = (_animationState select [0, _stateSegment select 0]) + _state + (_animationState select [(_stateSegment select 0) + (_stateSegment select 1)])
		} forEach (_x select 1);
	} forEach _replacements;

	_animationState
};

JBM_Heal =
{
	params ["_wounded", "_health"];

	private _hitPointDamage = +((getAllHitPointsDamage _wounded) select 2);

	// Set the global damage value to the average of all hit points
	private _damage = 0.0;
	{
		_damage = _damage + (_x min (1.0 - _health));
	} forEach _hitPointDamage;
	_wounded setDamage (_damage / count _hitPointDamage);

	// Set the individual hit point damage levels
	{
		_wounded setHitIndex [_forEachIndex, _x min (1.0 - _health)];
	} forEach _hitPointDamage;
};

JBM_R_HaveBeenRevived =
{
	_this spawn
	{
		params ["_medic", "_usedMedicFirstAidKit", ["_health", 1.0]];

		scriptName "JBM_R_HaveBeenRevived";

		if (lifeState player != "INCAPACITATED") exitWith { };

		// Speed up the revive animation.  Spawn the code that resets the animation speed to normal so that if ANYTHING goes wrong, we're sure to get that done

		private _animSpeedCoef = getAnimSpeedCoef player;
		player setAnimSpeedCoef (_animSpeedCoef * JBM_REVIVE_ANIMATION_ACCELERATION);
		[_animSpeedCoef] spawn
		{
			waitUntil { animationstate player find "amov" == 0 && animationstate player find "_" == -1 };
			player setAnimSpeedCoef (_this select 0);
		};

		[player, _health] call JBM_Heal;

		player setUnconscious false;
		[player] call JBM_MedicalCleanup;

		waitUntil { lifeState player != "INCAPACITATED" };

		if (not _usedMedicFirstAidKit) then
		{
			[player] call JBM_ConsumeFirstAidKit;
		};

		player playMoveNow "AmovPpneMstpSnonWnonDnon"; // Force roll prone.  setUnconscioue false won't do this if the player has slung/holstered his weapon
	};
};

JBM_ReviveWoundedPossible =
{
	params ["_wounded"];

	if (lifeState _wounded != "INCAPACITATED") exitWith { false };

	if (_wounded != player && { not (lifeState player in ["HEALTHY", "INJURED"]) }) exitWith { false };

	if (vehicle player != player) exitWith { false };

	if (not isPlayer _wounded) exitWith { false };

	if (player distance _wounded > JBM_MEDICAL_ACTION_DISTANCE) exitWith { false };

	if (not isNull attachedTo _wounded) exitWith { false };

	true
};

JBM_ReviveWoundedCondition =
{
	params ["_wounded"];

	if (not ([_wounded] call JBM_ReviveWoundedPossible)) exitWith { false };

	if ([animationState player, ["cin", "inv"]] call JB_fnc_matchAnimationState) exitWith { false };

	player setUserActionText [((player getVariable "JBM_Actions") select 3), format ["<t color=""#ED2744"">Revive %1</t>", name _wounded]];

	true
};

JBM_PlayTreatOtherAnimations =
{
	private _animations =
	[
		"AinvPknlMstpSnonWnonDnon_medic0",
		"AinvPknlMstpSnonWnonDnon_medic1",
		"AinvPknlMstpSnonWnonDnon_medic2",
		"AinvPknlMstpSnonWnonDnon_medic3",
		"AinvPknlMstpSnonWnonDnon_medic4",
		"AinvPknlMstpSnonWnonDnon_medic5"
	];

	if (stance player in ["STAND", "CROUCH"]) then { _animations = _animations apply { [_x, "medic", "medicUp"] call JB_fnc_replaceString } };
	if (currentWeapon player == primaryWeapon player) then { _animations = _animations apply { [_x, "w", "rfl"] call JB_fnc_setAnimationState } };

	while { count _animations > 0 } do { player playMove (_animations deleteAt (floor random count _animations)) };
};

JBM_ReviveWoundedInterrupted =
{
	params ["_entryAnimation"];

	player playMoveNow _entryAnimation;
};

JBM_ReviveWoundedCompleted =
{
	params ["_wounded", "_entryAnimation"];

	[_entryAnimation] call JBM_ReviveWoundedInterrupted;
	if ([_wounded] call JBM_ReviveWoundedPossible) then { [player, [player] call JBM_ConsumeFirstAidKit] remoteExec ["JBM_R_HaveBeenRevived", _wounded, false] };
};

JBM_ReviveWoundedHoldActionInterval =
{
	params ["_elapsedTime", "_progress", "_passthrough"];

	if (([JB_HA_STATE] call JB_fnc_holdActionGetValue) == "keyup") exitWith
	{
		[] call JB_fnc_holdActionStop;
		[_passthrough select 1] call JBM_ReviveWoundedInterrupted;
	};

	if (not ([_passthrough select 0] call JBM_ReviveWoundedPossible)) exitWith
	{
		[] call JB_fnc_holdActionStop;
		[_passthrough select 1] call JBM_ReviveWoundedInterrupted;
	};

	switch (true) do
	{
		case (_progress == 0.0):
		{
			(_passthrough select 0) setVariable ["JBM_ManuallyLoadedIntoVehicle", nil, true];
			[[format ["%1 is reviving you", name player], "plain down", 0.3]] remoteExec ["titleText", _passthrough select 0];
			[] call JBM_PlayTreatOtherAnimations;
		};

		case (_progress == 1.0):
		{
			[] call JB_fnc_holdActionStop;
			[_passthrough select 0, _passthrough select 1] call JBM_ReviveWoundedCompleted;
		};
	};
};

JBM_ReviveWoundedHoldAction =
{
	params ["_wounded", "_action"];

	if (not ([player] call JBM_FirstAidKitAvailable) && { not ([_wounded] call JBM_FirstAidKitAvailable) }) exitWith { ["A first aid kit is required to revive incapacitated soldiers", 1] call JB_fnc_showBlackScreenMessage };

	[actionKeys "action", 8.0, 1.0, JBM_ReviveWoundedHoldActionInterval, [_wounded, animationState player]] call JB_fnc_holdActionStart;
	[JB_HA_LABEL, str parseText ((player actionParams _action) select 0)] call JB_fnc_holdActionSetValue;
	[JB_HA_FOREGROUND_ICON, "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_reviveMedic_ca.paa"] call JB_fnc_holdActionSetValue;
};

JBM_ReviveWoundedInstant =
{
	params ["_wounded"];

	if (vehicle _wounded == _wounded && lifeState _wounded == "INCAPACITATED") then
	{
		_wounded setVariable ["JBM_ManuallyLoadedIntoVehicle", nil, true];
		[objNull, true] remoteExec ["JBM_R_HaveBeenRevived", _wounded];
	};
};

JBM_R_HaveBeenStabilized =
{
	_this spawn
	{
		params ["_medic", "_usedMedicFirstAidKit"];

		scriptName "JBM_R_HaveBeenStabilized";

		if (lifeState player != "INCAPACITATED") exitWith { };

		player setVariable ["JBM_Stabilized", true, true];

		if (not _usedMedicFirstAidKit) then
		{
			[player] call JBM_ConsumeFirstAidKit;
		};
	};
};

JBM_StabilizeWoundedPossible =
{
	params ["_wounded"];

	if (lifeState _wounded != "INCAPACITATED") exitWith { false };

	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	if ((_wounded getVariable ["JBM_Stabilized", false])) exitWith { false };

	if (vehicle player != player) exitWith { false };

	if (not isPlayer _wounded) exitWith { false };

	if (player distance _wounded > JBM_MEDICAL_ACTION_DISTANCE) exitWith { false };

	if (not isNull attachedTo _wounded) exitWith { false };

	true
};

JBM_StabilizeWoundedCondition =
{
	params ["_wounded"];

	if (not ([_wounded] call JBM_StabilizeWoundedPossible)) exitWith { false };

	if ([animationState player, ["cin", "inv"]] call JB_fnc_matchAnimationState) exitWith { false };

	player setUserActionText [((player getVariable "JBM_Actions") select 3), format ["<t color=""#ED2744"">Stabilize %1</t>", name _wounded]];

	true
};

JBM_StabilizeWoundedInterrupted =
{
	params ["_entryAnimation"];

	player playMoveNow _entryAnimation;
};

JBM_StabilizeWoundedCompleted =
{
	params ["_wounded", "_entryAnimation"];

	[_entryAnimation] call JBM_StabilizeWoundedInterrupted;
	if ([_wounded] call JBM_StabilizeWoundedPossible) then { [player, [player] call JBM_ConsumeFirstAidKit] remoteExec ["JBM_R_HaveBeenStabilized", _wounded, false] };
};

JBM_StabilizeWoundedHoldActionInterval =
{
	params ["_elapsedTime", "_progress", "_passthrough"];

	if (([JB_HA_STATE] call JB_fnc_holdActionGetValue) == "keyup") exitWith
	{
		[] call JB_fnc_holdActionStop;
		[_passthrough select 1] call JBM_StabilizeWoundedInterrupted;
	};

	if (not ([_passthrough select 0] call JBM_StabilizeWoundedPossible)) exitWith
	{
		[] call JB_fnc_holdActionStop;
		[_passthrough select 1] call JBM_StabilizeWoundedInterrupted;
	};

	switch (true) do
	{
		case (_progress == 0.0):
		{
			(_passthrough select 0) setVariable ["JBM_ManuallyLoadedIntoVehicle", nil, true];
			[[format ["%1 is stabilizing you", name player], "plain down", 0.3]] remoteExec ["titleText", _passthrough select 0];
			[] call JBM_PlayTreatOtherAnimations;
		};

		case (_progress == 1.0):
		{
			[] call JB_fnc_holdActionStop;
			[_passthrough select 0, _passthrough select 1] call JBM_StabilizeWoundedCompleted;
		};
	};
};

JBM_StabilizeWoundedHoldAction =
{
	params ["_wounded", "_action"];

	if (not ([player] call JBM_FirstAidKitAvailable) && { not ([_wounded] call JBM_FirstAidKitAvailable) }) exitWith { ["A first aid kit is required to stabilize wounded soldiers", 1] call JB_fnc_showBlackScreenMessage };

	[actionKeys "action", 8.0, 1.0, JBM_StabilizeWoundedHoldActionInterval, [_wounded, animationState player]] call JB_fnc_holdActionStart;
	[JB_HA_LABEL, str parseText ((player actionParams _action) select 0)] call JB_fnc_holdActionSetValue;
	[JB_HA_FOREGROUND_ICON, "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_reviveMedic_ca.paa"] call JB_fnc_holdActionSetValue;
};

JBM_GetMedicDragExitAnimation =
{
	params ["_medic"];

	private _medicAnimation = "";
	switch ([animationState _medic, "W"] call JB_fnc_getAnimationState) do
	{
		case "rfl" : { _medicAnimation = "AmovPknlMstpSlowWrflDnon" };
		case "pst" : { _medicAnimation = "AmovPknlMstpSlowWpstDnon" };
		default		 { _medicAnimation = "AmovPknlMstpSnonWnonDnon" };
	};
	_medicAnimation;
};

JBM_GetMedicCarryExitAnimation =
{
	params ["_medic"];

	private _medicAnimation = "";
	switch ([animationState _medic, "W"] call JB_fnc_getAnimationState) do
	{
		case "rfl" : { _medicAnimation = "AidlPknlMstpSlowWrflDnon_AI" };
		case "pst" : { _medicAnimation = "AidlPknlMstpSlowWpstDnon_AI" };
		case "non" : { _medicAnimation = "AidlPknlMstpSnonWnonDnon_AI" }; //BUG: plays move
	};

	_medicAnimation;
};

JBM_MovingIncapacitated =
{
	private _movingIncapacitated = objNull;
	{
		if (_x isKindOf "Man" && { lifeState _x == "INCAPACITATED" }) exitWith { _movingIncapacitated = _x };
	} forEach attachedObjects player;

	_movingIncapacitated;
};

JBM_SetDownWoundedCondition =
{
	private _incapacitated = [] call JBM_MovingIncapacitated;

	// If we notice that the player is stuck in the carry animation but doesn't have anyone to carry, break out 
	if (isNull _incapacitated && { [animationState player, 'cin'] call JB_fnc_matchAnimationState }) then
	{
		player switchMove "";
	};

	if (isNull _incapacitated) exitWith { false };

	player setUserActionText [((player getVariable "JBM_Actions") select 2), format ["<t color=""#ED2744"">Set down %1</t>", name _incapacitated]];

	true
};

JBM_SetDownWounded =
{
	private _medic = player;
	private _wounded = ([] call JBM_MovingIncapacitated);

	if ([animationState _medic, 'cin', 'knl'] call JB_fnc_matchAnimationState) then
	{
		[_medic, _wounded] remoteExec ["JBM_R_StopDrag"];
	}
	else
	{
		// Carry set down
		private _medicAnimation = [_medic] call JBM_GetMedicCarryExitAnimation;

		[_medic, _wounded, _medicAnimation] remoteExec ["JBM_R_StopCarry"];
	};
};

JBM_MoveWoundedCondition =
{
	params ["_wounded"];

	if ([animationState player, "cin"] call JB_fnc_matchAnimationState) exitWith { false };

	if (vehicle player != player) exitWith { false };

	if (lifeState _wounded != "INCAPACITATED") exitWith { false };

	if (not isNull attachedTo _wounded) exitWith { false };

	if ([animationState player, ["cin", "inv"]] call JB_fnc_matchAnimationState) exitWith { false };

	true;
};

JBM_DragWoundedCondition =
{
	params ["_wounded"];

	if (not ([_wounded] call JBM_MoveWoundedCondition)) exitWith { false };

	player setUserActionText [((player getVariable "JBM_Actions") select 0), format ["<t color=""#ED2744"">Drag %1</t>", name _wounded]];

	true
};

JBM_R_StartDrag =
{
	params ["_medic", "_wounded"];

	if (local _wounded) then
	{
		_wounded attachTo [_medic, [0, 1.3, 0.0]];
		_wounded setDir 180;
	};

	_medic playAction "grabdrag";
};

JBM_R_StopDrag =
{
	params ["_medic", "_wounded"];

	_medic playAction "released";

	if (local _wounded) then
	{
		detach _wounded;
	};
};

JBM_DragWounded =
{
	_this spawn
	{
		params ["_wounded"];

		if (lifeState _wounded != "INCAPACITATED") exitWith {};

		private _medic = player;

		scriptName "JBM_DragWounded";

		_wounded setVariable ["JBM_ManuallyLoadedIntoVehicle", nil, true];

		[_medic, _wounded] remoteExec ["JBM_R_StartDrag"];

		// Wait until in drag animation
		waitUntil { [animationState _medic, "cin", "knl"] call JB_fnc_matchAnimationState || { !(lifeState _medic in ["HEALTHY", "INJURED"]) } };

		if ([animationState _medic, "cin", "knl"] call JB_fnc_matchAnimationState) then
		{
			waitUntil { sleep 0.2; !([animationState _medic, "cin", "knl"] call JB_fnc_matchAnimationState) || { !(lifeState _medic in ["HEALTHY", "INJURED"]) } || { lifeState _wounded != "INCAPACITATED" } };
		};

		// If we're left dragging, get out of it
		if ([animationState _medic, "cin", "knl"] call JB_fnc_matchAnimationState) then
		{
			_medic playAction "released";
			[_medic, _wounded] remoteExec ["JBM_R_StopDrag"];
		};
	};
};

JBM_FrameNumber = 0;

JBM_VehiclePointsFrameNumber = 0;
JBM_VehiclePoints = [];

JBM_PointOccupants =
{
	params ["_point"];

	private _name = _point select 0;
	private _vehicle = _point select 1;

	private _occupants = [];

	switch (typeName _name) do
	{
		case "ARRAY" :
		{
			private _turretPath = _name select 1;
			_occupants = (fullCrew [_vehicle, "", true]) select { (_x select 3) isEqualTo _turretPath } apply { _x select 0 };
		};
		case "STRING" :
		{
			switch (_name) do
			{
				case "driver" :
				{
					_occupants pushBack (driver _vehicle);
				};
				case "commander" :
				{
					_occupants pushBack (commander _vehicle);
				};
				case "gunner" :
				{
					_occupants pushBack (gunner _vehicle);
				};
				case "codriver" :
				{
					// codriver: [is-codriver-a-cargo-position, index-of-cargo-position-for-codriver]
					private _codriver = getArray (configFile >> "CfgVehicles" >> typeOf _vehicle >> "cargoIsCoDriver");
					private _cargoIndex = if (_coDriver select 0 == 1) then { _codriver select 1 } else { 0 };
					_occupants pushBack ((fullCrew [_vehicle, "cargo", true]) select _cargoIndex select 0);
				};
				case "cargo" :
				{
					private _codriver = getArray (configFile >> "CfgVehicles" >> typeOf _vehicle >> "cargoIsCoDriver");
					_occupants = (fullCrew [_vehicle, "cargo", true]) select { _coDriver select 0 == 0 || { _coDriver select 1 != _x select 2 } } apply { _x select 0 };
				};
			};
		};
	};

	_occupants;
};

JBM_PointHasVacancies =
{
	params ["_point"];

	private _hasVacancies = false;

	{
		if (isNull _x) exitWith { _hasVacancies = true };
	} forEach ([_point] call JBM_PointOccupants);

	_hasVacancies;
};

JBM_PointHasIncapacitated =
{
	params ["_point"];

	private _hasIncapacitated = false;

	{
		if (!(isNull _x) && { lifeState _x == "INCAPACITATED" }) exitWith { _hasIncapacitated = true };
	} forEach ([_point] call JBM_PointOccupants);

	_hasIncapacitated;
};

JBM_SetupLoadAction =
{
	params ["_point", "_actionIndex"];

	private _actionTitle = "";

	if ([_point] call JBM_PointHasVacancies) then
	{
		private _name = _point select 0;

		private _description = "";
		if (typeName _name == "ARRAY") then
		{
			_description = "as " + (_name select 0);
		}
		else // STRING
		{
			if (_name == "cargo") then
			{
				_description = "in back";
			}
			else
			{
				_description = "as " + _name;
			}
		};

		_actionTitle = format ["<t color=""#ED2744"">Load wounded %1</t>", _description];
	};

	private _action = JBM_LoadActions select _actionIndex;
	player setUserActionText [_action, _actionTitle];
};

JBM_SetupUnloadAction =
{
	params ["_point", "_actionIndex"];

	private _actionTitle = "";

	if ([_point] call JBM_PointHasIncapacitated) then
	{
		private _name = _point select 0;

		private _description = "";
		if (typeName _name == "ARRAY") then
		{
			_description = "from " + (_name select 0);
		}
		else // STRING
		{
			if (_name == "cargo") then
			{
				_description = "from back";
			}
			else
			{
				_description = "from " + _name;
			}
		};

		_actionTitle = format ["<t color=""#ED2744"">Unload wounded %1</t>", _description];
	};

	private _action = JBM_UnloadActions select _actionIndex;
	player setUserActionText [_action, _actionTitle];
};

JBM_GetNearbyVehiclePoints =
{
	params ["_position", "_proximity"];

	private _vehiclePoints = [];

	{
		private _vehicle = _x;
		private _size = sizeOf (typeOf _vehicle);

		if (_position distance _vehicle < _size) then
		{
			private _name = "";
			{
				_name = _x select 0;
				{
					if (count _x == 0 || { _position distance (_x select 0) < _proximity }) then { _vehiclePoints pushBack [_name, _vehicle]; };
				} forEach (_x select 1);
			} forEach ([_vehicle, ["driver", "codriver", "gunner", "cargo", "turret"]] call JB_fnc_getInPoints);
		};
	} forEach nearestObjects [_position, ["LandVehicle", "Air", "Ship"], 15]; // Allow for largest distance on vehicle from center to 'get in point'.

	_vehiclePoints;
};

JBM_SetupLoadUnloadActions =
{
	JBM_VehiclePoints = [getPos player, 1.5] call JBM_GetNearbyVehiclePoints;

	private _actionIndex = 0;
	{
		[_x, _actionIndex] call JBM_SetupLoadAction;
		_actionIndex = _actionIndex + 1;
		if (_actionIndex == count JBM_LoadActions) exitWith {};
	} forEach JBM_VehiclePoints;

	for "_i" from _actionIndex to (count JBM_LoadActions) - 1 do
	{
		player setUserActionText [JBM_LoadActions select _i, ""];
	};

	_actionIndex = 0;
	{
		[_x, _actionIndex] call JBM_SetupUnloadAction;
		_actionIndex = _actionIndex + 1;
		if (_actionIndex == count JBM_UnloadActions) exitWith {};
	} forEach JBM_VehiclePoints;

	for "_i" from _actionIndex to (count JBM_UnloadActions) - 1 do
	{
		player setUserActionText [JBM_UnloadActions select _i, ""];
	};
};

JBM_LoadWoundedCondition =
{
	private _pointIndex = param [0, 0, [0]];

	if (!([animationState player, "cin"] call JB_fnc_matchAnimationState)) exitWith { false };

	if (isNull ([] call JBM_MovingIncapacitated)) exitWith { false };

	if (JBM_VehiclePointsFrameNumber < JBM_FrameNumber) then
	{
		JBM_VehiclePointsFrameNumber = JBM_FrameNumber;
		[] call JBM_SetupLoadUnloadActions;
	};

	private _params = player actionParams (JBM_LoadActions select _pointIndex);

	if ((_params select 0) == "") exitWith { false };

	true
};

JBM_MoveInVehicle =
{
	params ["_vehicle", "_name", "_unit"];

	switch (typeName _name) do
	{
		case "ARRAY" :
		{
			_unit assignAsTurret [_vehicle, _name select 1];
			_unit moveInTurret [_vehicle, _name select 1];
		};
		case "STRING" :
		{
			switch (_name) do
			{
				case "driver" :
				{
					_unit assignAsDriver _vehicle;
					_unit moveInDriver _vehicle;
				};
				case "commander" :
				{
					_unit assignAsCommander _vehicle;
					_unit moveInCommander _vehicle;
				};
				case "gunner" :
				{
					_unit assignAsGunner _vehicle;
					_unit moveInGunner _vehicle;
				};
				case "codriver" :
				{
					private _codriver = getArray (configFile >> "CfgVehicles" >> typeOf _vehicle >> "cargoIsCoDriver");
					private _cargoIndex = if (_coDriver select 0 == 1) then { _codriver select 1 } else { 0 };
					_unit assignAsCargoIndex [_vehicle, _cargoIndex];
					_unit moveInCargo [_vehicle, _cargoIndex];
				};
				case "cargo" :
				{
					private _codriver = getArray (configFile >> "CfgVehicles" >> typeOf _vehicle >> "cargoIsCoDriver");
					{
						if (isNull (_x select 0) && ( _coDriver select 0 == 0 || { _coDriver select 1 != _x select 2 } )) exitWith
						{
							_unit assignAsCargoIndex [_vehicle, _x select 2];
							_unit moveInCargo [_vehicle, _x select 2];
						};
					} forEach fullCrew [_vehicle, "cargo", true];
				};
			};
		};
	};
};

JBM_R_LoadWounded =
{
	params ["_point", "_wounded", "_medic", "_medicAnimation"];

	private _name = _point select 0;
	private _vehicle = _point select 1;

	if (local _wounded) then
	{
		_wounded setVariable ["JBM_ManuallyLoadedIntoVehicle", true, true];
		[_vehicle, _name, _wounded] call JBM_MoveInVehicle;
	};

	waitUntil { vehicle _wounded == _vehicle };
	_wounded playMoveNow "unconscious";

	_medic switchMove _medicAnimation;
};

JBM_LoadWounded =
{
	private _pointIndex = param [0, 0, [0]];

	private _point = JBM_VehiclePoints select _pointIndex;

	private _wounded = ([] call JBM_MovingIncapacitated);
	detach _wounded;

	private _medicAnimation = "";
	if ([animationState player, 'cin', 'knl'] call JB_fnc_matchAnimationState) then
	{
		_medicAnimation = [player] call JBM_GetMedicDragExitAnimation;
	}
	else
	{
		_medicAnimation = [player] call JBM_GetMedicCarryExitAnimation;
	};

	[_point, _wounded, player, _medicAnimation] remoteExec ["JBM_R_LoadWounded"];
};

JBM_R_StartCarry =
{
	_this spawn
	{
		params ["_medic", "_wounded", "_medicAnimation"];

		scriptName "JBM_R_StartCarry";

		if (not local _wounded) then
		{
			waitUntil { attachedTo _wounded == _medic };

			_wounded switchMove "AinjPfalMstpSnonWrflDf_carried"; // AinjPfalMstpSnonWnonDf_wounded_dead
			_medic switchMove _medicAnimation;
		}
		else
		{
			_wounded attachTo [_medic, [-0.15, 0.1, 0.0]];
			_wounded setdir 180;

			_wounded switchMove "AinjPfalMstpSnonWrflDf_carried"; // AinjPfalMstpSnonWnonDf_wounded_dead
			_medic switchMove _medicAnimation;
		};
	};
};

JBM_R_StopCarry =
{
	_this spawn
	{
		params ["_medic", "_wounded", "_medicAnimation"];

		scriptName "JBM_R_StopCarry";

		if (local _wounded) then
		{
			detach _wounded;
			_wounded setPos (_medic modelToWorld [0,1,0]);
			_wounded setDir ((getDir _medic) + 90);
		};

		_medic switchMove _medicAnimation;
		_wounded switchMove "unconsciousrevivedefault";
	};
};

JBM_R_CarryWoundedSwitchMove =
{
	params ["_medic", "_wounded", "_medicAnimation"];

	_medic switchMove _medicAnimation;
	_wounded switchMove "AinjPfalMstpSnonWrflDf_carried";
};

JBM_R_CarryWoundedFromVehicle =
{
	params ["_medic", "_wounded", "_medicAnimation"];

	private _manuallyLoaded = _wounded getVariable ["JBM_ManuallyLoadedIntoVehicle", false];

	_wounded setUnconscious false;
	moveOut _wounded;
	_wounded setUnconscious true;

	waitUntil { vehicle _wounded == _wounded };

	if (_manuallyLoaded) then
	{
		_wounded setVariable ["JBM_ManuallyLoadedIntoVehicle", nil, true]; // public

		waitUntil { [animationState _wounded, "*", "erc"] call JB_fnc_matchAnimationState };

		_wounded attachTo [_medic, [-0.15, 0.1, 0.0]];
		_wounded setdir 180;

		[_medic, _wounded, _medicAnimation] remoteExec ["JBM_R_CarryWoundedSwitchMove"];
	};
};

JBM_CarryWoundedCondition =
{
	params ["_wounded"];

	if (not ([_wounded] call JBM_MoveWoundedCondition)) exitWith { false };

	player setUserActionText [((player getVariable "JBM_Actions") select 1), format ["<t color=""#ED2744"">Carry %1</t>", name _wounded]];

	true
};

JBM_CarryWounded =
{
	_this spawn
	{
		params ["_wounded"];

		if (lifeState _wounded != "INCAPACITATED") exitWith {};

		scriptName "JBM_CarryWounded";

		private _medic = player;

		private _medicAnimation = "";
		switch (currentWeapon _medic) do
		{
			case (primaryWeapon _medic) : { _medicAnimation = "AcinPercMstpSrasWrflDnon" };
			case (handgunWeapon _medic) : { _medicAnimation = "AcinPercMstpSnonWpstDnon" };
			default						  { _medicAnimation = "AcinPercMstpSnonWnonDnon" }; //BUG: Medic slides instead of walking
		};

		if (vehicle _wounded == _wounded) then
		{
			[_medic, _wounded, _medicAnimation] remoteExec ["JBM_R_StartCarry"];
		}
		else
		{
			[_medic, _wounded, _medicAnimation] remoteExec ["JBM_R_CarryWoundedFromVehicle", _wounded];
		};

		// Wait until in carry animation
		waitUntil { [animationState _medic, "cin", "erc"] call JB_fnc_matchAnimationState || { !(lifeState _medic in ["HEALTHY", "INJURED"]) } };

		if ([animationState _medic, "cin", "erc"] call JB_fnc_matchAnimationState) then
		{
			waitUntil { sleep 0.2; !([animationState _medic, "cin", "erc"] call JB_fnc_matchAnimationState) || { !(lifeState _medic in ["HEALTHY", "INJURED"]) } || { lifeState _wounded != "INCAPACITATED" } };
		};

		// If we're left carrying, get out of it
		if ([animationState _medic, "cin", "erc"] call JB_fnc_matchAnimationState) then
		{
			private _medicAnimation = [_medic] call JBM_GetMedicCarryExitAnimation;
			[_medic, _wounded, _medicAnimation] remoteExec ["JBM_R_StopCarry"];
		};
	};
};

JBM_UnloadWoundedCondition =
{
	private _pointIndex = param [0, 0, [0]];

	if ([animationState player, ["cin", "inv"]] call JB_fnc_matchAnimationState) exitWith { false };

	if (JBM_VehiclePointsFrameNumber < JBM_FrameNumber) then
	{
		JBM_VehiclePointsFrameNumber = JBM_FrameNumber;
		[] call JBM_SetupLoadUnloadActions;
	};

	private _params = player actionParams (JBM_UnloadActions select _pointIndex);

	// If the action has a blank name then we're not using it
	(_params select 0) != ""
};

JBM_UnloadWounded =
{
	private _pointIndex = param [0, 0, [0]];

	private _point = JBM_VehiclePoints select _pointIndex;

	private _occupants = [_point] call JBM_PointOccupants;

	private _incapacitated = objNull;

	{
		if (!(isNull _x) && { lifeState _x == "INCAPACITATED" }) exitWith { _incapacitated = _x };
	} forEach _occupants;

	if (!isNull _incapacitated) then
	{
		[_incapacitated] call JBM_CarryWounded;
	};
};

JBM_SetupActions =
{
	params ["_player"];

	private _action = 0;
	private _actions = [];

	_action = _player addAction ["<t color=""#ED2744"">Drag wounded</t>", { [cursorObject] call JBM_DragWounded }, nil, 20, false, true, "", "(player distance cursorObject) <= JBM_MEDICAL_ACTION_DISTANCE && { [cursorObject] call JBM_DragWoundedCondition }"];
	_actions pushBack _action; // 0

	_action = _player addAction ["<t color=""#ED2744"">Carry wounded</t>", { [cursorObject] call JBM_CarryWounded }, nil, 20, false, true, "", "(player distance cursorObject) <= JBM_MEDICAL_ACTION_DISTANCE && { [cursorObject] call JBM_CarryWoundedCondition }"];
	_actions pushBack _action; // 1

	_action = _player addAction ["<t color=""#ED2744"">Set down wounded</t>", { [] call JBM_SetDownWounded }, nil, 20, true, false, "", "[] call JBM_SetDownWoundedCondition"];
	_actions pushBack _action; // 2

	// Medics revive, everyone else stabilizes

	if (_player getUnitTrait "medic") then
	{
		_action = _player addAction ["<t color=""#ED2744"">Revive wounded</t>", { [cursorObject, _this select 2] call JBM_ReviveWoundedHoldAction }, nil, 20, true, true, "", "(player distance cursorObject) <= JBM_MEDICAL_ACTION_DISTANCE && { [cursorObject] call JBM_ReviveWoundedCondition }"];
		_actions pushBack _action; // 3

		[_player, _action, "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_reviveMedic_ca.paa"] call JB_fnc_holdActionSetText;
	}
	else
	{
		_action = _player addAction ["<t color=""#ED2744"">Stabilize wounded</t>", { [cursorObject, _this select 2] call JBM_StabilizeWoundedHoldAction }, nil, 20, true, true, "", "(player distance cursorObject) <= JBM_MEDICAL_ACTION_DISTANCE && { [cursorObject] call JBM_StabilizeWoundedCondition }"];
		_actions pushBack _action; // 4

		[_player, _action, "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_reviveMedic_ca.paa"] call JB_fnc_holdActionSetText;
	};

	_player setVariable ["JBM_Actions", _actions];

	JBM_LoadActions = [];
	JBM_LoadActions pushBack (_player addAction ["Load wounded 0", { [0] call JBM_LoadWounded }, nil, 20, false, true, "", "[0] call JBM_LoadWoundedCondition"]);
	JBM_LoadActions pushBack (_player addAction ["Load wounded 1", { [1] call JBM_LoadWounded }, nil, 20, false, true, "", "[1] call JBM_LoadWoundedCondition"]);
	JBM_LoadActions pushBack (_player addAction ["Load wounded 2", { [2] call JBM_LoadWounded }, nil, 20, false, true, "", "[2] call JBM_LoadWoundedCondition"]);
	JBM_LoadActions pushBack (_player addAction ["Load wounded 3", { [3] call JBM_LoadWounded }, nil, 20, false, true, "", "[3] call JBM_LoadWoundedCondition"]);

	JBM_UnloadActions = [];
	JBM_UnloadActions pushBack (_player addAction ["Unload wounded 0", { [0] call JBM_UnloadWounded }, nil, 20, false, true, "", "[0] call JBM_UnloadWoundedCondition"]);
	JBM_UnloadActions pushBack (_player addAction ["Unload wounded 1", { [1] call JBM_UnloadWounded }, nil, 20, false, true, "", "[1] call JBM_UnloadWoundedCondition"]);
	JBM_UnloadActions pushBack (_player addAction ["Unload wounded 2", { [2] call JBM_UnloadWounded }, nil, 20, false, true, "", "[2] call JBM_UnloadWoundedCondition"]);
	JBM_UnloadActions pushBack (_player addAction ["Unload wounded 3", { [3] call JBM_UnloadWounded }, nil, 20, false, true, "", "[3] call JBM_UnloadWoundedCondition"]);
};