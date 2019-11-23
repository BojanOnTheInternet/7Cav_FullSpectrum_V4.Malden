// Handling of placed mines.  Mine dispensers must be recorded, then the TouchOffMines action must be spotted, then the dispensed mines must be identified.

// Notify players within this distance of a placed explosive
#define EXPLOSIVES_PROXIMITY_WARNING_RANGE 20

// Reveal minelets within this distance when a mine dispenser is triggered
#define MINE_DISPENSER_RANGE 30

// How long it takes for minelets to be dispersed and on the ground
#define MINE_DISPERSAL_DELAY 4.0

player setVariable ["CLIENT_MineDispensers", []];
player addEventHandler ["Fired",
	{
		if (_this select 1 != "Put") exitWith {};

		private _magazine = _this select 5;
		
		// We're only interested in the various types of explosives here
		if (not (_magazine isKindOf ["ATMine_Range_Mag", configFile >> "CfgMagazines"]) &&
			{ not (_magazine isKindOf ["SatchelCharge_Remote_Mag", configFile >> "CfgMagazines"]) } &&
			{ not (_magazine isKindOf ["ClaymoreDirectionalMine_Remote_Mag", configFile >> "CfgMagazines"]) }) exitWith {};

		// Warn nearby players when the explosive is placed
		private _nearbyPlayers = allPlayers select { _x distance player < EXPLOSIVES_PROXIMITY_WARNING_RANGE };
		[[name player, _magazine], { systemchat format ["%1 has placed an explosive (%2)", _this select 0, getText (configFile >> "CfgMagazines" >> (_this select 1) >> "displayName")] }] remoteExec ["call", _nearbyPlayers];

		// Make sure the players can see where the explosive was placed
		playerSide revealMine (_this select 6);

		// If the charge is a mine dispenser, then add it to the list of mine dispensers.  If triggered, we'll reveal the minelets that it dispenses.
		if (_magazine isKindOf ["APERSMineDispenser_Mag", configFile >> "CfgMagazines"]) then
		{
			(player getVariable "CLIENT_MineDispensers") pushBack (_this select 6);
		};
	}];

CLIENT_RevealDispersedMines =
{
	private _dispensers = player getVariable ["CLIENT_MineDispensers", []];
	player setVariable ["CLIENT_MineDispensers", []];

	if (count _dispensers == 0) exitWith { false };

	[_dispensers apply { getPos _x }] spawn
	{
		private _waitingForFirstMinelet = true;
		private _nearbyMinelets = [];
		private _unknownMinelets = [];
		private _position = [];

		while { true } do
		{
			sleep 1;

			_nearbyMinelets = [];
			{
				_position = _x;
				_nearbyMinelets append (allMines select { _x distance _position < MINE_DISPENSER_RANGE && { _x isKindOf "APERSMineDispenser_Mine_Ammo" } });
			} forEach (_this select 0);

			_unknownMinelets = _nearbyMinelets - detectedMines playerSide;
			if (count _unknownMinelets == 0 && not _waitingForFirstMinelet) exitWith {};
			if (count _unknownMinelets > 0) then { _waitingForFirstMinelet = false };

			{ playerSide revealMine _x } forEach _unknownMinelets;
		};
	};

	false
};

["TouchOffMines", CLIENT_RevealDispersedMines, { false }, { false }] call CLIENT_OverrideAction; //TODO: Key and button activation